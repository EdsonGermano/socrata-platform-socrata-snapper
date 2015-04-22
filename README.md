Instructions for using socrata-snapper
=====================================
page snap and comparison tool

The tool has the ability to navigate to, sign-in (in the case of Socrata sites) and take a snap shot of a web page. It also can look at the page for any javascript errors.

### Prerequisites
* the following components are required to run this tool
  * fileutils
  * nokogiri
  * selenium-webdriver
  * optparse
  * chunky_png
  * logger
  * httparty
  * phantomjs
  * json
  * uri
  * core/auth/client (which is Socrata internal and has been included with the project until such time as that gem is made publicly available)

### Operations possibilities:
* navigate to a site and snap a picture when no authentication is required (public opendata sites)
```bash
$ ./snapper-caller.rb -m snap -s domain:4x4
$ example: ruby snapper-caller.rb -m snap -s data.seattle.gov:mags-97de
```

* navigate to a site directly and snap a picture (any public sites)
```bash
$ ./snapper-caller.rb -m snap -s url -o true
$ note: bare_url = https://<some_url> without the https://
$ example: ruby snapper-caller.rb -m snap -s www.microsoft.com -o
```

* navigate to an obe site, login and snap a picture
```bash
$ ./snapper-caller.rb -m snap -s domain:4x4 -u <username> -p <password>
$ example: ruby snapper-caller.rb -m snap -s opendata-demo.rc-socrata.com:6q4t-m6c7 -u [SOCRATA_USER] -p [SOCRATA_PASSWORD]
```

* navigate to two sites, compare and produce a diff of them.
```bash
$ ./snapper-caller.rb -m diff -s domain:4x4 -d domain:4x4
$ example: ruby snapper-caller.rb -m snap -s opendata-demo.rc-socrata.com:6q4t-m6c7 -d opendata-demo.rc-socrata.com:b5k5-ycfq
```

* navigate to two sites, login, compare and produce a diff of them.
```bash
$ ./snapper-caller.rb -m diff -s domain:4x4 -d domain:4x4  -u <username> -p <password>
$ example: ruby snapper-caller.rb -m snap -s opendata-demo.rc-socrata.com:6q4t-m6c7 -d opendata-demo.rc-socrata.com:b5k5-ycfq -u [SOCRATA_USER] -p [SOCRATA_PASSWORD]
```

* navigate to a publicly accessible (non-authenticated) site and take a snapshot of the DataLens page when no OBE page is available
```bash
$ ./snapper-caller.rb -m snap -s url -o true
$ note: url = https://<some_url> without the https://
$ example: ruby snapper-caller.rb -m snap -s data.cityofchicago.org/view/2bnm-jnvb
```

* navigate to a DataLens page, authenticate and take a picture (TBD)


### order of operations
  1. goto site
  2. login if needed
  3. navigate to next location if needed
  4. snapshot the page and save it
  5. check for javascript errors if requested
  6. check for pageload errors if requested

### FAQ
* My browsers are opening at different sizes. What can I do about that?
  * This issue is under investigation. It may require changing to the Watir driver but the jury is out as of this writing.
