import math
import numpy as np

from sklearn.utils.class_weight import compute_class_weight

from keras import models
from keras import layers
from keras import optimizers

from callbacks import get_callbacks
from setup import (
    save_class_indices,
    get_training_directories,
    get_cnn_data_generators,
    get_image_batches,
    get_conv_base,
    top_3_categorical_accuracy,
    top_2_categorical_accuracy,
)
from config import MODEL_CONFIG


def get_cnn_model(pretrained_cnn, no_cats):
    conv_base = get_conv_base(pretrained_cnn)
    conv_base.trainable = False

    model = models.Sequential()
    model.add(conv_base)
    model.add(layers.Flatten())
    model.add(layers.Dense(256, activation="relu"))
    model.add(layers.Dropout(0.3))
    model.add(layers.Dense(no_cats, activation="softmax"))

    print(model.summary())
    print(len(model.trainable_weights))
    return model


def build_compile_cnn(cnn, no_cats):
    model = get_cnn_model(cnn, no_cats)
    model.compile(
        optimizer=optimizers.RMSprop(),
        loss="categorical_crossentropy",
        metrics=["acc", top_2_categorical_accuracy, top_3_categorical_accuracy],
    )
    return model


def train_model():
    pre_trained_cnn = MODEL_CONFIG["pre_trained_cnn"]
    batch_size = MODEL_CONFIG["batch_size"]
    epochs = MODEL_CONFIG["epochs"]
    model_name = MODEL_CONFIG["model_name"]
    base_dir = MODEL_CONFIG["base_dir"]
    no_cats = MODEL_CONFIG["no_cats"]

    train_dir, validation_dir, test_dir = get_training_directories(base_dir)

    train_datagen, test_datagen = get_cnn_data_generators(cnn=pre_trained_cnn)

    train_generator, validation_generator, test_generator = get_image_batches(
        train_datagen, train_dir, test_datagen, validation_dir, test_dir, batch_size, cnn=pre_trained_cnn
    )

    save_class_indices(validation_generator, "class_indices_cafe")

    model = build_compile_cnn(pre_trained_cnn, no_cats)

    callbacks = get_callbacks(f"{pre_trained_cnn}_{model_name}", train_generator)

    class_weights = compute_class_weight("balanced", np.unique(train_generator.classes), train_generator.classes)

    history = model.fit_generator(
        train_generator,
        steps_per_epoch=math.ceil(train_generator.samples / train_generator.batch_size),
        epochs=epochs,
        verbose=1,
        validation_data=validation_generator,
        callbacks=callbacks,
        class_weight=class_weights,
    )
