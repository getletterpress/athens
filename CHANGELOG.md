## 0.3.0 / 2019-07-02

* Added enumerator-based result access methods: `#rows` and `#records`
* Fixed bug dropping headers from memoized rows across `#to_h` and `#to_a(header_row: true)`

## 0.2.0 / 2019-03-20

* Added support for NULL values.  Columns with a nullable status of "NULLABLE" or "UNKNOWN" will return nil for NULL values
* If a NOT_NULL column returns a nil value an InvalidNullError will be raised

## 0.1.0 / 2019-03-01

* Initial release!