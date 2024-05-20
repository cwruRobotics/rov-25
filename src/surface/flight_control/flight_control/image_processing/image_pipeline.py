#!/usr/bin/env python3
from PIL import Image
import numpy as np
import matplotlib.pyplot as plt
from image_processing.square_detector import SquareDetector
import argparse
import cv2

square_detector = SquareDetector()


def debug_process_image_file(image_path: str, do_collage: bool) -> None:
    # Open the image using Pillow
    img = Image.open(image_path)
    img = img.convert("RGB")

    # Convert the image to a NumPy array (OpenCV image!) for easier manipulation
    original_img = np.array(img)

    corners, result_img = \
        square_detector.process_image(original_img, do_collage, True)
    print("FINAL CORNERS:", corners)

    if result_img is not None:
        print(result_img.shape)
        print(type(corners), type(corners[0]), type(result_img), type(result_img.shape))
    #     result_img, rotation_vector, translation_vector, intrinsic_matrix, dist_coefs = \
    #         deproject_with_annotation(result_img, corners)

        if do_collage:
            plt.figure(figsize=(12, 8))  # fig size is the size of the window.
            plt.imshow(result_img)
            plt.title('Result Image')
            plt.axis('off')
            # plt.show()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', type=str, default='./test_images/basic.png', help='Input image path')
    args = parser.parse_args()

    input_image_path = args.i
    debug_process_image_file(input_image_path, True)

    # show whatever plot diagram was prepared:
    plt.show()
