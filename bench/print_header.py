import bench

if __name__ == "__main__":
    d = bench.PREFIXES + ["name"]
    print(",".join(sorted(d)))