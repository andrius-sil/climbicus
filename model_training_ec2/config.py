MODEL_CONFIG = {
    # 'base_dir': "../model_training/data/sets/categories_castle_cafe_categories_blurred_photos_removed",
    'base_dir': "../model_training/data/sets/categories_castle_cafe_categories_blurred_photos_removed",
    'no_cats': 47,
    'pre_trained_cnn': "vgg16",  # 'vgg16', 'inception' or 'xception'
    'batch_size': 14,  # trade off between speed of training and accuracy of the weights
    'epochs': 100,
    'model_name': 'test',
}
