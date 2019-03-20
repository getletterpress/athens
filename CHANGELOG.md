## 0.2.0 / 2019-03-20

* Added support for NULL values.  Columns with a nullable status of "NULLABLE" or "UNKNOWN" will return nil for NULL values
* If a NOT_NULL column returns a nil value an InvalidNullError will be raised

## 0.1.0 / 2019-03-01

* Initial release!