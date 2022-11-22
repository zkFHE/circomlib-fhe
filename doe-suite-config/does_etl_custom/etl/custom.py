from doespy.etl.steps.extractors import Extractor
from doespy.etl.steps.transformers import Transformer
from doespy.etl.steps.loaders import Loader, PlotLoader

import pandas as pd
from typing import Dict, List
import matplotlib.pyplot as plt


class MyExtractor(Extractor):
    def file_regex_default(self):
        return [r".*\.txt$", r".*\.log$"]

    def extract(self, path: str, options: Dict) -> List[Dict]:
        print("MyExtractor: do nothing")
        return [{}]


class MyTransformer(Transformer):
    def transform(self, df: pd.DataFrame, options: Dict) -> pd.DataFrame:
        print(f"MyTransformer: do nothing  ({df.info()})")
        return df


class MyLoader(Loader):
    def load(self, df: pd.DataFrame, options: Dict, etl_info: Dict) -> None:
        print(f"MyLoader: do nothing  ({df.info()})")
        # Any result should be stored in:
        # output_dir = self.get_output_dir(etl_info)


class MyPlotLoader(PlotLoader):
    def load(self, df: pd.DataFrame, options: Dict, etl_info: Dict) -> None:
        print(f"MyPlotLoader: do nothing  ({df.info()})")
        if not df.empty:
            fig = self.plot(df)
            output_dir = self.get_output_dir(etl_info)
            self.save_plot(fig, filename="test", output_dir=output_dir)

    def plot(self, df):
        fig = plt.figure()
        return fig
