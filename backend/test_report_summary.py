import unittest

from main import get_random_summary_lines


class ReportSummaryTest(unittest.TestCase):
    def test_high_score_uses_excellent_set(self):
        lines = get_random_summary_lines(92)

        self.assertEqual(3, len(lines))
        self.assertTrue(any("normal" in line.lower()
                        or "excellent" in line.lower() for line in lines))

    def test_low_score_uses_loss_set(self):
        lines = get_random_summary_lines(35)

        self.assertEqual(3, len(lines))
        self.assertTrue(any("hearing loss" in line.lower() or "threshold" in line.lower(
        ) or "consult" in line.lower() for line in lines))


if __name__ == "__main__":
    unittest.main()
