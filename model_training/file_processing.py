import os
import shutil
import random
from PIL import Image


SEED = 101


def get_filenames(mypath):
    onlyfiles = [f for f in os.listdir(mypath) if not f.startswith(".")]
    return onlyfiles


def overwrite_dir(dir):
    if os.path.exists(dir):
        shutil.rmtree(dir)
    os.makedirs(dir)


def listdir_no_hidden(path):
    dirs = [i for i in os.listdir(path) if not i.startswith(".")]
    return dirs


def compress_and_save(image_path, dest_image_path):
    image = Image.open(image_path)
    newImage = image.resize((299, 299), Image.LANCZOS)
    newImage.save(dest_image_path, "JPEG", quality=90)


def save_image_to_folder(filenames_and_paths, data_path, split_type, c, compress):
    for filename, path in filenames_and_paths.items():
        if compress:
            compress_and_save(path, f"{data_path}/{split_type}/{c}/{filename}")
        else:
            shutil.copyfile(path, f"{data_path}/{split_type}/{c}/{filename}")


def copy_images_to_set_folders(all_filenames_and_paths, set_base_path, c, compress):
    for set_type, filenames_and_paths in all_filenames_and_paths.items():
        for filename, path in filenames_and_paths.items():
            if compress:
                compress_and_save(path, f"{set_base_path}/{set_type}/{c}/{filename}")
            else:
                shutil.copyfile(path, f"{set_base_path}/{set_type}/{c}/{filename}")


def split_train_test(base_dir, set_sizes, compress=True):
    data_path = os.path.join("data", base_dir)
    set_base_path = os.path.join("data/sets", base_dir.replace("/", "_"))

    for set_type, size in set_sizes.items():
        overwrite_dir(os.path.join(set_base_path, f"{set_type}/"))

    list_of_cats = listdir_no_hidden(data_path)

    for c in list_of_cats:
        category_path = os.path.join(data_path, f"{c}/")
        list_of_filenames = get_filenames(category_path)
        random.seed(SEED)

        filenames_and_paths = {}
        for set_type, size in set_sizes.items():
            filenames_and_paths[set_type] = {}
            os.makedirs(os.path.join(set_base_path, f"{set_type}/{c}/"))
            if size > 0:
                for _ in range(size):
                    choice = random.choice(list_of_filenames)
                    filenames_and_paths[set_type][choice] = os.path.join(category_path, choice)
                    list_of_filenames.remove(choice)
            # Implement the usage the remaining photos in one of the sets
        while len(list_of_filenames) > 0:
            choice = random.choice(list_of_filenames)
            random_set = random.choice(list(set_sizes.keys()))
            filenames_and_paths[random_set][choice] = os.path.join(category_path, choice)
            list_of_filenames.remove(choice)

        copy_images_to_set_folders(filenames_and_paths, set_base_path, c, compress)
