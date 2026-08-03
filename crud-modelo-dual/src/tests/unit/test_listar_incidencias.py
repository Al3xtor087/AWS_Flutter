import importlib.util
import pathlib
import sys
import types
import unittest

class DummyResource:
    def Table(self, *args, **kwargs):
        return None

sys.modules['boto3'] = types.SimpleNamespace(resource=lambda *args, **kwargs: DummyResource())

module_path = pathlib.Path(__file__).resolve().parents[2] / 'listar_incidencias.py'
spec = importlib.util.spec_from_file_location('listar_incidencias', module_path)
listar_incidencias = importlib.util.module_from_spec(spec)
spec.loader.exec_module(listar_incidencias)


class AplicarFiltrosTest(unittest.TestCase):
    def test_filtra_por_fecha_cuando_llega_query_param(self):
        resultados = [
            {'fecha': '2026-07-13', 'tipoIncidencia': {'nombre': 'Falta'}},
            {'fecha': '2026-07-14', 'tipoIncidencia': {'nombre': 'Retardo'}},
        ]

        filtrados = listar_incidencias.aplicar_filtros(resultados, {'fecha': '2026-07-13'})

        self.assertEqual(len(filtrados), 1)
        self.assertEqual(filtrados[0]['fecha'], '2026-07-13')


if __name__ == '__main__':
    unittest.main()
