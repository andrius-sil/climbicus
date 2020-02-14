import os
import pickle

from keras.applications import VGG16
from keras.applications.inception_v3 import InceptionV3
from keras.applications.xception import Xception
from keras.preprocessing.image import ImageDataGenerator
from keras.metrics import top_k_categorical_accuracy

from keras.applications.vgg16 import preprocess_input as preprocess_input_vgg16
from keras.applications.inception_v3 import preprocess_input as preprocess_input_inception
from keras.applications.xception import preprocess_input as preprocess_input_xception


def save_class_indices(generator, filename):
    class_indices_opp = {v: k for k, v in generator.class_indices.items()}

    def save_obj(obj, name):
        with open(name + ".pkl", "wb") as f:
            pickle.dump(obj, f, pickle.HIGHEST_PROTOCOL)

    save_obj(class_indices_opp, filename)


def get_training_directories(base_dir):
    train_dir = os.path.join(base_dir, "train")
    validation_dir = os.path.join(base_dir, "val")
    test_dir = os.path.join(base_dir, "test")
    return train_dir, validation_dir, test_dir


def get_cnn_data_generators(cnn):
    if cnn == "vgg16":
        pre_processor = preprocess_input_vgg16
    elif cnn == "inception":
        pre_processor = preprocess_input_inception
    elif cnn == "xception":
        pre_processor = preprocess_input_xception
    else:
        raise ValueError(f"Unknown pre-trained CNN. Got {cnn} whereas vgg16, inception or exception is expected.")

    train_datagen = ImageDataGenerator(
        preprocessing_function=pre_processor,
        # brightness_range=(0.003, 1.6),
        rotation_range=180,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        fill_mode="nearest",
    )

    test_datagen = ImageDataGenerator(preprocessing_function=pre_processor)
    return train_datagen, test_datagen


def get_image_batches(train_datagen, train_dir, test_datagen, validation_dir, test_dir, batch_size, cnn):
    # Different pre-trained CNN's use different target images sizes as input
    if cnn == "vgg16":
        target_size = (224, 224)  # All images will be resized to 224x224
    elif cnn == "inception":
        target_size = (299, 299)  # All images will be resized to 299x99
    elif cnn == "xception":
        target_size = (299, 299)  # All images will be resized to 299x299
    else:
        raise ValueError(f"Unknown pre-trained CNN. Got {cnn} whereas vgg16, inception or exception is expected.")

    train_generator = train_datagen.flow_from_directory(
        train_dir,
        target_size=target_size,
        batch_size=batch_size,
        class_mode="categorical",
        shuffle=True,
        # save_to_dir='train_samples'
    )

    validation_generator = test_datagen.flow_from_directory(
        validation_dir,
        target_size=target_size,
        batch_size=batch_size,
        class_mode="categorical",
        shuffle=False,
        # save_to_dir='val_samples'
    )

    test_generator = test_datagen.flow_from_directory(
        test_dir, target_size=target_size, batch_size=batch_size, class_mode="categorical", shuffle=False
    )

    return train_generator, validation_generator, test_generator


def get_conv_base(cnn):
    if cnn == "vgg16":
        conv_base = VGG16(weights="imagenet", include_top=False, input_shape=(224, 224, 3))
    elif cnn == "inception":
        conv_base = InceptionV3(weights="imagenet", include_top=False, input_shape=(299, 299, 3))
    elif cnn == "xception":
        conv_base = Xception(weights="imagenet", include_top=False, input_shape=(299, 299, 3))
    else:
        raise ValueError(f"Unknown pre-trained CNN. Got {cnn} whereas vgg16, inception or exception is expected.")

    return conv_base


def top_3_categorical_accuracy(y_true, y_pred):
    return top_k_categorical_accuracy(y_true, y_pred, k=3)


def top_2_categorical_accuracy(y_true, y_pred):
    return top_k_categorical_accuracy(y_true, y_pred, k=2)
