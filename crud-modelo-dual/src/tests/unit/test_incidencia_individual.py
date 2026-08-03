import json
import sys
from decimal import Decimal
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import incidencia_individual


class IncidenciaIndividualDeleteTests(unittest.TestCase):
    def test_delete_removes_item_from_dynamodb(self):
        class FakeTable:
            def __init__(self):
                self.deleted_key = None

            def delete_item(self, Key, ReturnValues):
                self.deleted_key = Key
                return {"Attributes": {"id": Key["id"]}}

        fake_table = FakeTable()
        incidencia_individual.tabla = fake_table

        event = {
            "httpMethod": "DELETE",
            "pathParameters": {"id": "INC-123"},
        }

        response = incidencia_individual.lambda_handler(event, None)

        self.assertEqual(response["statusCode"], 200)
        self.assertEqual(fake_table.deleted_key, {"id": "INC-123"})

    def test_delete_serializes_decimal_attributes(self):
        class FakeTable:
            def __init__(self):
                self.deleted_key = None

            def delete_item(self, Key, ReturnValues):
                self.deleted_key = Key
                return {"Attributes": {"id": Key["id"], "monto": Decimal("3.14")}}

        fake_table = FakeTable()
        incidencia_individual.tabla = fake_table

        event = {
            "httpMethod": "DELETE",
            "pathParameters": {"id": "INC-123"},
        }

        response = incidencia_individual.lambda_handler(event, None)

        self.assertEqual(response["statusCode"], 200)
        body = json.loads(response["body"])
        self.assertEqual(body["incidencia"]["monto"], 3.14)


if __name__ == "__main__":
    unittest.main()
