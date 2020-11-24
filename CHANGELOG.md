## 0.3.2 / 2020-11-24

* Added optional `request_token` and `work_group` parameters to the query execute method (thanks [mediafinger](https://github.com/mediafinger))

## 0.3.1 / 2020-07-20

* Bumped development rake version from 0.10 to 0.13 for security fixes
* Fixed warning about string defaulting to string (#2)

## 0.3.0 / 2019-07-02

* Added enumerator-based result access methods: `#rows` and `#records`
* Fixed bug dropping headers from memoized rows across `#to_h` and `#to_a(header_row: true)`

## 0.2.0 / 2019-03-20

* Added support for NULL values.  Columns with a nullable status of "NULLABLE" or "UNKNOWN" will return nil for NULL values
* If a NOT_NULL column returns a nil value an InvalidNullError will be raised

## 0.1.0 / 2019-03-01

* Initial release!