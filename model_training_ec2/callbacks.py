import os
import time

from keras.callbacks import EarlyStopping, ModelCheckpoint, TensorBoard, LearningRateScheduler

logs_base_dir = "callbacks"


def exponential_decay(lr0, s):
    def exponential_decay_fn(epoch):
        return lr0 * 0.1 ** (epoch / s)

    return exponential_decay_fn


def get_callbacks(model_name, train_generator):
    model_id = time.strftime("%Y-%m-%d_%H-%M-%S")
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
    tensorboard_log_dir = os.path.join(logs_base_dir, "logs", f"{model_name}_{model_id}")
    callback_tensorboard = TensorBoard(
        log_dir=tensorboard_log_dir,
        histogram_freq=0,
        write_graph=True,
        write_grads=True,
        batch_size=train_generator.samples / train_generator.batch_size,
        write_images=True,
    )
    callback_early_stopping = EarlyStopping(monitor="val_loss", mode="auto", verbose=1, patience=10)

    exponential_decay_fn = exponential_decay(lr0=0.0001, s=200)
    lr_scheduler = LearningRateScheduler(exponential_decay_fn)

    return [callback_model, callback_early_stopping, lr_scheduler]  #callback_tensorboard
