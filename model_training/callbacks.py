import io
import itertools
import os
import time

import numpy as np
from sklearn.metrics import confusion_matrix

import matplotlib.pyplot as plt
import skimage
import tensorflow as tf
from keras.callbacks import Callback, CSVLogger, EarlyStopping, LambdaCallback, ModelCheckpoint, TensorBoard

logs_base_dir = "callbacks"


def plot_to_image(figure):
    """Converts the matplotlib plot specified by 'figure' to a PNG image and
    returns it. The supplied figure is closed and inaccessible after this call."""
    # Save the plot to a PNG in memory.
    buf = io.BytesIO()
    plt.savefig(buf, format="png")
    # Closing the figure prevents it from being displayed directly inside
    # the notebook.
    plt.close(figure)
    buf.seek(0)
    # Convert PNG buffer to TF image
    image = tf.image.decode_png(buf.getvalue(), channels=4)
    # Add the batch dimension
    image = tf.expand_dims(image, 0)
    return image


def plot_confusion_matrix(cm, class_names):
    """
    Returns a matplotlib figure containing the plotted confusion matrix.

    Args:
    cm (array, shape = [n, n]): a confusion matrix of integer classes
    class_names (array, shape = [n]): String names of the integer classes
    """
    figure = plt.figure(figsize=(8, 8))
    plt.imshow(cm, interpolation="nearest", cmap=plt.cm.Blues)
    plt.title("Confusion matrix")
    plt.colorbar()
    tick_marks = np.arange(len(class_names))
    plt.xticks(tick_marks, class_names, rotation=45)
    plt.yticks(tick_marks, class_names)

    # Normalize the confusion matrix.
    cm = np.around(cm.astype("float") / cm.sum(axis=1)[:, np.newaxis], decimals=2)

    # Use white text if squares are dark; otherwise black.
    threshold = cm.max() / 2.0
    for i, j in itertools.product(range(cm.shape[0]), range(cm.shape[1])):
        color = "white" if cm[i, j] > threshold else "black"
        plt.text(j, i, cm[i, j], horizontalalignment="center", color=color)

    plt.tight_layout()
    plt.ylabel("True label")
    plt.xlabel("Predicted label")
    return figure


def log_confusion_matrix(epoch, logs, model, validation_generator,  log_dir):
    # Use the model to predict the values from the validation dataset.
    y_pred_raw = model.predict_generator(
        validation_generator, validation_generator.samples // validation_generator.batch_size
    )
    y_pred = np.argmax(y_pred_raw, axis=1)
    cm = confusion_matrix(validation_generator.classes, y_pred)
    # Calculate the confusion matrix.
    # Log the confusion matrix as an image summary.
    figure = plot_confusion_matrix(cm, class_names=list(validation_generator.class_indices.keys()))
    cm_image = plot_to_image(figure)

    # Log the confusion matrix as an image summary.
    file_writer_cm = tf.summary.create_file_writer(os.path.join(log_dir, "cm"))
    with file_writer_cm.as_default():
    tf.summary.image("Confusion Matrix", cm_image, step=epoch)


class LRTensorBoard(TensorBoard):
    def __init__(self, log_dir, **kwargs):
        super().__init__(log_dir=log_dir, **kwargs)

    def on_epoch_end(self, epoch, logs=None):
        logs.update({"lr": K.eval(self.model.optimizer.lr)})  # Store learning rate as lr in the event folder
        super().on_epoch_end(epoch, logs)


class TensorBoardImage(Callback):
    def __init__(self, tag, log_dir):
        super().__init__()
        self.tag = tag
        self.log_dir = log_dir

    def on_epoch_end(self, epoch, logs={}):
        # Load image
        img = skimage.data.astronaut()
        # Do something to the image
        img = (255 * skimage.util.random_noise(img)).astype("uint8")

        writer = tf.summary.create_file_writer(os.path.join( self.log_dir, "td"))
        with writer.as_default():
            img = np.reshape(img, (-1, 512, 512, 3))
            tf.summary.image("Training data", img, step=epoch)


def get_callbacks(model_name, model, train_generator, validation_generator):
    model_id = time.strftime("%Y-%m-%d_%H-%M-%S")
    log_dir = os.path.join(logs_base_dir, f"{model_name}_{model_id}")
    callback_csv = CSVLogger(
        filename=os.path.join(logs_base_dir, f"{model_name}_{model_id}.csv"), separator=",", append=False
    )
    os.makedirs(os.path.join(logs_base_dir, "models"), exist_ok=True)
    callback_model = ModelCheckpoint(
        filepath=os.path.join(logs_base_dir, "models", f"{model_name}_{model_id}.hdf5"),
        monitor="val_loss",
        verbose=1,
        save_best_only=True,
        save_weights_only=True,
        mode="auto",
        period=3,
    )
    callback_tensorboard = TensorBoard(
        log_dir=os.path.join(logs_base_dir, "logs", f"{model_name}_{model_id}"),
        histogram_freq=0,
        write_graph=True,
        write_grads=True,
        batch_size=train_generator.samples / train_generator.batch_size,
        write_images=True,
    )
    # callback_learning_rate = LRTensorBoard(log_dir=os.path.join(logs_base_dir, 'logs', f'{model_name}_{model_id}'))

    callback_early_stopping = EarlyStopping(monitor="val_loss", mode="auto", verbose=1, patience=5)
    tbi_callback = TensorBoardImage("Example image", log_dir)
    cm_callback = LambdaCallback(
        on_epoch_end=lambda epoch, logs: log_confusion_matrix(epoch, logs, model, validation_generator, log_dir)
    )
    return [
        callback_csv,
        callback_model,
        callback_tensorboard,
        # callback_learning_rate,
        callback_early_stopping,
        tbi_callback,
        cm_callback,
    ]
