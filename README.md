Instructions for using socrata-snapper
=====================================
page snap and comparison tool

The tool has the ability to navigate to, sign-in (in the case of Socrata sites) and take a snap shot of a web page. It also can look at the page for any javascript errors.

### Prerequisites
* run bundle install to install dependencies.

### Operations possibilities:
### Snapping -
*navigate to a site and snap a picture when no authentication is required (public opendata sites)*
```bash
$ ./snapper-caller.rb -m snap -s domain:4x4
$ example: ruby snapper-caller.rb -m snap -s data.seattle.gov:mags-97de
```

*navigate to a secure site (https) directly and snap a picture (any public sites). -o is only used for taking snapshots.*
```bash
$ ./snapper-caller.rb -m snap -s url -o
$ note: bare_url = https://<some_url> without the https://
$ example: ruby snapper-caller.rb -m snap -s www.microsoft.com -o
```

*navigate to an insecure site (http) directly and snap a picture (any public sites). -i is only honored in combination with -o*
```bash
$ ./snapper-caller.rb -m snap -s url -o -i
$ note: bare_url = http://<some_url> without the http://
$ example: ruby snapper-caller.rb -m snap -s www.microsoft.com -o -i
```

*navigate to an obe site, login and snap a picture*
```bash
$ ./snapper-caller.rb -m snap -s domain:4x4 -u <username> -p <password>
$ example: ruby snapper-caller.rb -m snap -s opendata-demo.rc-socrata.com:6q4t-m6c7 -u [SOCRATA_USER] -p [SOCRATA_PASSWORD]
```

*navigate to a publicly accessible (non-authenticated) site and take a snapshot of the DataLens page when no OBE page is available*

**in diff mode the tool is expecting the OBE 4x4 and will find the NBE 4x4 on its own. -o is only used for taking snapshots.**
```bash
$ ./snapper-caller.rb -m snap -s url -o
$ note: url = https://<some_url> without the https://
$ example: ruby snapper-caller.rb -m snap -s data.cityofchicago.org/view/2bnm-jnvb
```

*navigate to a DataLens page, authenticate and take a picture (TBD)*


#### Diffing -
*navigate to two sites, compare and produce a diff of them.*

**In diff mode the tool is expecting the OBE 4x4 and will find the NBE 4x4 on its own**
```bash
$ ./snapper-caller.rb -m diff -s domain:4x4 -d domain:4x4
$ example: ruby snapper-caller.rb -m diff -s opendata-demo.rc-socrata.com:6q4t-m6c7 -d opendata-demo.rc-socrata.com:b5k5-ycfq
```

*navigate to two sites, login, compare and produce a diff of them.*

**in diff mode the tool is expecting the OBE 4x4 and will find the NBE 4x4 on its own**
```bash
$ ./snapper-caller.rb -m diff -s domain:4x4 -d domain:4x4  -u <username> -p <password>
$ example: ruby snapper-caller.rb -m diff -s opendata-demo.rc-socrata.com:6q4t-m6c7 -d opendata-demo.rc-socrata.com:b5k5-ycfq -u [SOCRATA_USER] -p [SOCRATA_PASSWORD]
```

##### FAQ
**My browsers are opening at different sizes. What can I do about that?**

This issue is under investigation. It may require changing to the Watir driver but the jury is out as of this writing.
