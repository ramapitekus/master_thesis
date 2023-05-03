import numpy as np
import pickle
import pandas as pd
import os
import time
import sklearn


LOG_PATH = "../logs/classifier.log"
MODEL_PATH = "./models/rfClassifier.model"
CSV_PATH = "../logs/logfile{}.csv"
TIME_WINDOW = 5.0
clf = pickle.load(open(MODEL_PATH, "rb"))

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


def count_reads(series):
    reads = series.loc[lambda x: x == "read"]
    return reads.count()


def count_writes(series):
    writes = series.loc[lambda x: x == "write"]
    return writes.count()


def prepare_dataset(df, group_by_pid=False):
    df["entropy"] = df["entropy"].replace(-1, np.NaN)
    df["time_id"] = df["timestamp"] // TIME_WINDOW
    df = df.drop("timestamp", axis=1)

    df["entropy_ext_type"] = np.where((df["ext"].isin(LOW_ENTROPY_EXTENSIONS)) & (df["op"] == "write"), True, False)

    if group_by_pid:
        df["sum_writes"] = df.groupby(["time_id", "pid"])["op"].transform(count_writes)
        df["sum_reads"] = df.groupby(["time_id", "pid"])["op"].transform(count_reads)
        df = df[df["entropy_ext_type"] != False]
        df_grouped = df.groupby(["time_id", "sum_writes", "sum_reads", "entropy_ext_type", "pid"], dropna=False).agg({"entropy": ["min", "mean", "max"]})
    else:
        df["sum_writes"] = df.groupby(["time_id"])["op"].transform(count_writes)
        df["sum_reads"] = df.groupby(["time_id"])["op"].transform(count_reads)
        df = df[df["entropy_ext_type"] != False]
        df_grouped = df.groupby(["time_id", "sum_writes", "sum_reads", "entropy_ext_type"], dropna=False).agg({"entropy": ["min", "mean", "max"]})

    df_grouped.columns = ['_'.join(col) for col in df_grouped.columns]
    df_grouped = df_grouped.reset_index()

    df_grouped = df_grouped.drop("entropy_ext_type", axis=1)

    return df_grouped


def main():
    counter = 0
    while True:
        if not os.path.exists(CSV_PATH.format(counter)):
            time.sleep(TIME_WINDOW)
        else:
            stream_df = pd.read_csv(CSV_PATH.format(counter))
            counter += 1

            row = prepare_dataset(stream_df, group_by_pid=True)
            if row.empty:
                continue
            features = ["entropy_max", "entropy_mean", "entropy_min", "sum_writes", "sum_reads"]
            row = row.loc[:, features]
            row = row.fillna(value={"entropy_max": 0, "entropy_min": 0, "entropy_mean": 0})
            pred = clf.predict(row)

            with open(LOG_PATH, "w") as classifier:
                if 0 in pred:
                    print("Ransomware detected - terminating...")
                    classifier.write("true")
                    break
                else:
                    classifier.write("false")


main()
