import math
import os
import sys
import tempfile
import unittest

import cv2
import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import image_compare  # noqa: E402


def rgba(h, w, color):
    a = np.zeros((h, w, 4), dtype=np.uint8)
    a[...] = color
    return a


class DiffMetricsTest(unittest.TestCase):
    def test_identical(self):
        a = rgba(4, 5, (10, 20, 30, 255))
        m = image_compare.diff_metrics(a, a.copy())
        self.assertTrue(m.shape_match)
        self.assertEqual(m.max_abs, 0)
        self.assertEqual(m.mean_abs, 0.0)
        self.assertTrue(math.isinf(m.psnr))

    def test_difference(self):
        a = rgba(2, 2, (10, 10, 10, 255))
        b = a.copy()
        b[0, 0, 0] = 14
        m = image_compare.diff_metrics(a, b)
        self.assertEqual(m.max_abs, 4)
        self.assertAlmostEqual(m.mean_abs, 4 / 16)
        self.assertAlmostEqual(m.psnr, 10 * math.log10(255 ** 2 / (16 / 16)))

    def test_shape_mismatch(self):
        m = image_compare.diff_metrics(rgba(2, 2, 0), rgba(3, 2, 0))
        self.assertFalse(m.shape_match)
        self.assertIsNone(m.max_abs)

    def test_gray_vs_gray(self):
        a = np.full((3, 3), 100, dtype=np.uint8)
        m = image_compare.diff_metrics(a, a + 1)
        self.assertEqual(m.max_abs, 1)


class ToDisplayTest(unittest.TestCase):
    def test_gray_becomes_rgb(self):
        got = image_compare.to_display_rgb(np.full((2, 3), 7, dtype=np.uint8))
        self.assertEqual(got.shape, (2, 3, 3))
        self.assertTrue((got == 7).all())

    def test_rgba_is_composited_on_white(self):
        a = rgba(1, 1, (0, 0, 0, 0))
        self.assertEqual(image_compare.to_display_rgb(a).tolist(), [[[255, 255, 255]]])
        b = rgba(1, 1, (10, 20, 30, 255))
        self.assertEqual(image_compare.to_display_rgb(b).tolist(), [[[10, 20, 30]]])


class MakeSheetTest(unittest.TestCase):
    def test_panels_with_different_sizes_are_padded(self):
        sheet = image_compare.make_sheet([("a", rgba(10, 20, (1, 2, 3, 255))),
                                          ("b", np.zeros((30, 5), dtype=np.uint8))])
        self.assertEqual(sheet.ndim, 3)
        self.assertEqual(sheet.shape[2], 3)
        self.assertGreaterEqual(sheet.shape[0], 30)
        self.assertGreaterEqual(sheet.shape[1], 20 + 5)


class RunTest(unittest.TestCase):
    def test_writes_reference_and_compare(self):
        with tempfile.TemporaryDirectory() as d:
            src = rgba(4, 6, (200, 100, 50, 255))
            cv2.imwrite(os.path.join(d, "in.png"), cv2.cvtColor(src, cv2.COLOR_RGBA2BGRA))
            os.makedirs(os.path.join(d, "matft"))
            flipped = src[::-1].copy()
            cv2.imwrite(os.path.join(d, "matft", "flip.png"), cv2.cvtColor(flipped, cv2.COLOR_RGBA2BGRA))
            cases = {
                "flip": image_compare.Case("in.png", lambda x: cv2.flip(x, 0), "vertical flip"),
                "nomatft": image_compare.Case("in.png", lambda x: x, "no Matft output"),
            }
            results = image_compare.run(d, cases)

            by_name = {r.name: r for r in results}
            self.assertEqual(by_name["flip"].status, "ok")
            self.assertEqual(by_name["flip"].metrics.max_abs, 0)
            self.assertEqual(by_name["nomatft"].status, "missing-matft")
            self.assertTrue(os.path.exists(os.path.join(d, "opencv", "flip.png")))
            self.assertTrue(os.path.exists(os.path.join(d, "compare", "flip.png")))
            self.assertFalse(os.path.exists(os.path.join(d, "compare", "nomatft.png")))

    def test_reports_matft_output_without_case(self):
        with tempfile.TemporaryDirectory() as d:
            os.makedirs(os.path.join(d, "matft"))
            cv2.imwrite(os.path.join(d, "matft", "orphan.png"), np.zeros((2, 2), dtype=np.uint8))
            results = image_compare.run(d, {})
            self.assertEqual([(r.name, r.status) for r in results], [("orphan", "missing-case")])


if __name__ == "__main__":
    unittest.main()
