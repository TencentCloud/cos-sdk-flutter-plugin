class Utils {
  static String readableStorageSize(int sizeInB)  {
    double floatSize = sizeInB.toDouble();
    int index = 0;
    List units = ["B", "KB", "MB", "GB", "TB", "PB"];

    while (floatSize > 1000 && index < 5) {
    index++;
    floatSize /= 1024;
    }

    return '${floatSize.toStringAsFixed(2)}${units[index]}';
  }
}
