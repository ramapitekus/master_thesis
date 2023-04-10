import numpy as np
import pickle
import pandas as pd
import os
import time
import sklearn


LOW_ENTROPY_EXTENSIONS = [
    'bmp',
    'csv',
    'dbase3',
    'doc',
    'eps',
    'f',
    'fits',
    'gls',
    'html',
    'java',
    'kml',
    'log',
    'ps',
    'rtf',
    'sgml',
    'tex',
    'text',
    'troff',
    'ttf',
    'txt',
    'unk',
    'vrml',
    'wp',
    'xls',
    'xml'
]

LOG_PATH = "../rename_fs/logs/classifier.log"
# MODEL_PATH = "./models/IsolationForest.model"
MODEL_PATH = "./models/model_group_by_id_isolation_forest.model"
CSV_PATH = "../rename_fs/logs/logfile0.csv"

clf = pickle.load(open(MODEL_PATH, "rb"))


class Watcher:
    def __init__(self):
        self.timestamp = -1


def count_reads(series):
    # reads = series.filter(items=["read"])
    reads = series.loc[lambda x: x == "read"]
    return reads.count()


def count_writes(series):
    writes = series.loc[lambda x: x == "write"]
    return writes.count()


def prepare_dataset(df):
    df["entropy"] = df["entropy"].replace(-1, np.NaN)
    df["time_id"] = df["timestamp"] // 10
    df = df.drop("timestamp", axis=1)

    df["entropy_ext_type"] = np.where((df["ext"].isin(LOW_ENTROPY_EXTENSIONS)) & (df["op"] == "write"), True, False)

    df["sum_writes"] = df.groupby(["time_id"])["op"].transform(count_writes)
    df["sum_reads"] = df.groupby(["time_id"])["op"].transform(count_reads)

    df_grouped = df.groupby(["time_id", "sum_writes", "sum_reads", "entropy_ext_type"], dropna=False).agg({"entropy": ["min", "mean", "max"]})
    df_grouped.columns = ['_'.join(col) for col in df_grouped.columns]
    df_grouped = df_grouped.reset_index()

    df_grouped = df_grouped[df_grouped["entropy_ext_type"] != False].drop("entropy_ext_type", axis=1)

    return df_grouped


def main():
    file_watcher = Watcher()
    stamp = os.stat(CSV_PATH).st_mtime
    while True:
        time.sleep(0.5)
        if stamp != file_watcher.timestamp:
            file_watcher.timestamp = stamp
            stream_df = pd.read_csv(CSV_PATH)

            row = prepare_dataset(stream_df)
            features = ["entropy_max", "entropy_min", "entropy_mean", "sum_writes", "sum_reads"]
            # row = row[features]
            clf.predict(row)


main()