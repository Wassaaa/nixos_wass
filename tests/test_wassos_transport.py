import contextlib
import io
import unittest

from wassos_transport import main


class TransportTests(unittest.TestCase):
    def test_no_task_is_reported(self):
        with contextlib.redirect_stderr(io.StringIO()) as errors:
            self.assertEqual(main(), 1)
        self.assertIn("No NixOS transport task is currently prepared", errors.getvalue())


if __name__ == "__main__":
    unittest.main()
