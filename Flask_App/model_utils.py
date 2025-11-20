import os
import uuid
import shutil
import pandas as pd
import numpy as np
import cv2
import tensorflow as tf
from tensorflow.keras.models import Model
from tensorflow.keras.layers import GlobalAveragePooling2D, Dense, Dropout, BatchNormalization
from tensorflow.keras.applications import EfficientNetB5
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.preprocessing.image import (
    load_img, img_to_array, array_to_img, ImageDataGenerator
)
from tensorflow.keras.regularizers import l2

# === Class dictionary ===
classes = {
    'nv': 'Melanocytic nevi',
    'mel': 'Melanoma',
    'bkl': 'Benign keratosis-like lesions',
    'bcc': 'Basal cell carcinoma',
    'akiec': 'Actinic keratoses',
    'vasc': 'Vascular lesions',
    'df': 'Dermatofibroma'
}

# === Load or Create Model ===
def load_model(model_path):
    if os.path.exists(model_path):
        return tf.keras.models.load_model(model_path)
    else:
        return create_new_model(model_path)

def create_new_model(model_path):
    IMAGE_SIZE = 456  # EfficientNetB5 default input size
    BATCH_SIZE = 32
    num_classes = 7
    # Load EfficientNetB5 without top layer
    base_model = EfficientNetB5(weights='imagenet', include_top=False, input_shape=(IMAGE_SIZE, IMAGE_SIZE, 3))
    base_model.trainable = False
    for layer in base_model.layers:
        if layer.name == 'block6a_expand_conv':
            layer.trainable = True

    # Custom classification head
    x = base_model.output
    x = GlobalAveragePooling2D()(base_model.output)
    x = Dropout(0.5)(x)

    x = Dense(256, activation='relu', kernel_regularizer=l2(0.001))(x)
    x = BatchNormalization()(x)

    x = Dropout(0.3)(x)
    x = Dense(128, activation='relu', kernel_regularizer=l2(0.001))(x)
    x = BatchNormalization()(x)

    x = Dropout(0.2)(x)
    output = Dense(num_classes, activation='softmax', kernel_regularizer=l2(0.001))(x)

    model = Model(inputs=base_model.input, outputs=output)

    model.compile(optimizer=Adam(learning_rate=1e-4), loss='categorical_crossentropy', metrics=['accuracy'])

    # Print model summary
    model.summary()
def preprocess_image(image_path, IMAGE_SIZE=456):
    img = cv2.imread(image_path)
    if img is None:
        return None

    # First check if it's human skin
    if not is_human_skin(img):
        return None
    img = cv2.imread(image_path)
    img = cv2.resize(img, (IMAGE_SIZE, IMAGE_SIZE))
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    blackhat = cv2.morphologyEx(gray, cv2.MORPH_BLACKHAT, cv2.getStructuringElement(cv2.MORPH_RECT, (17, 17)))
    inpainted = cv2.inpaint(img, blackhat, 1, cv2.INPAINT_TELEA)
    denoised = cv2.GaussianBlur(inpainted, (7, 7), 0)
    return denoised

    return processed


def is_human_skin(img):
    img = cv2.resize(img, (456, 456))

    # --- HSV range for skin tone ---
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    lower = np.array([0, 30, 60], dtype=np.uint8)
    upper = np.array([25, 180, 255], dtype=np.uint8)
    skin_mask = cv2.inRange(hsv, lower, upper)
    skin_ratio = cv2.countNonZero(skin_mask) / (img.shape[0] * img.shape[1])

    # --- Texture analysis (blurred or sharp?) ---
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()

    # --- Color variance (cartoons/images are flat) ---
    stddev_color = np.std(img)

    # --- Final decision logic ---
    if skin_ratio < 0.1:
        return False  # Not enough skin-like pixels
    if laplacian_var < 40:
        return False  # Too smooth — likely cartoon/vector
    if stddev_color < 25:
        return False  # Too little color variation — likely artificial

    return True


# === Updated Prediction ===
def predict_image(model, image_path):
    processed_img = preprocess_image(image_path)
    if processed_img is None:
        return {
            'class': 'unknown',
            'class_id': 'unknown',
            'confidence': 0.0,
            'description': 'The image does not appear to be human skin or could not be processed',
            'is_skin': False
        }

    img_array = tf.keras.applications.efficientnet.preprocess_input(processed_img)
    img_array = np.expand_dims(img_array, axis=0)
    predictions = model.predict(img_array)
    predicted_class_idx = np.argmax(predictions[0])
    class_id = list(classes.keys())[predicted_class_idx]
    class_name = classes[class_id]
    confidence = float(np.max(predictions[0]))

    return {
        'class': class_name,
        'class_id': class_id,
        'confidence': confidence,
        'description': get_class_description(class_id),
        'is_skin': True
    }
# === Class Description ===
def get_class_description(class_id):
    descriptions = {
        'nv': "Melanocytic nevi are common moles.",
        'mel': "Melanoma is the most serious type of skin cancer.",
        'bkl': "Benign keratosis-like lesions are non-cancerous skin growths.",
        'bcc': "Basal cell carcinoma is the most common type of skin cancer.",
        'akiec': "Actinic keratoses are precancerous growths caused by sun exposure.",
        'vasc': "Vascular lesions include blood vessel-related skin conditions.",
        'df': "Dermatofibroma is a benign skin lesion."
    }
    return descriptions.get(class_id, "No description available.")

# === Augmentation for Class Balancing ===
def balance_with_augmentation(train_df, output_dir="/kaggle/working/augmented_dataset", IMAGE_SIZE=224):
    os.makedirs(output_dir, exist_ok=True)
    class_counts = train_df['class_code'].value_counts()
    max_count = class_counts.max()
    majority_class = class_counts.idxmax()

    for label in train_df['class_code'].unique():
        class_folder = os.path.join(output_dir, label)
        os.makedirs(class_folder, exist_ok=True)
        class_df = train_df[train_df['class_code'] == label]
        for _, row in class_df.iterrows():
            src = row['image_path']
            dst = os.path.join(class_folder, os.path.basename(src))
            if not os.path.exists(dst):
                shutil.copy(src, dst)

    augmenter = ImageDataGenerator(
        rotation_range=30,
        width_shift_range=0.2,
        height_shift_range=0.2,
        brightness_range=[0.2, 0.5],
        horizontal_flip=True,
        vertical_flip=True,
        fill_mode='reflect'
    )

    augmented_records = []

    for label in class_counts.index:
        if label == majority_class:
            print(f"Skipping augmentation for majority class '{label}'")
            continue

        class_df = train_df[train_df['class_code'] == label]
        current_count = len(class_df)
        n_needed = max_count - current_count
        class_folder = os.path.join(output_dir, label)
        generated = 0

        while generated < n_needed:
            for _, row in class_df.iterrows():
                try:
                    img = load_img(row['image_path'], target_size=(IMAGE_SIZE, IMAGE_SIZE))
                    x = img_to_array(img).reshape((1,) + (IMAGE_SIZE, IMAGE_SIZE, 3))

                    for batch in augmenter.flow(x, batch_size=1):
                        out_filename = f"{uuid.uuid4().hex}.jpg"
                        out_path = os.path.join(class_folder, out_filename)
                        array_to_img(batch[0]).save(out_path)
                        augmented_records.append({'image_path': out_path, 'class_code': label})
                        generated += 1
                        break
                    if generated >= n_needed:
                        break
                except Exception as e:
                    print(f"Augmentation error on {row['image_path']}: {e}")

    augmented_df = pd.DataFrame(augmented_records)
    final_train_df = pd.concat([train_df, augmented_df], ignore_index=True)
    return final_train_df