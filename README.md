Instructions for using socrata-snapper
=====================================
page snap and comparison tool

The tool has the ability to navigate to, sign-in (in the case of Socrata sites) and take a snap shot of a web page. It also can look at the page for any javascript errors.

### Prerequisites
* run ```bundle install``` to install dependencies.

### Operations possibilities:
### Snapping -
*navigate to a site and snap a picture when no authentication is required (public opendata sites)*
```bash
$ ./snapper-caller.rb -m snap -s domain|OBE_4x4
$ example: ruby snapper-caller.rb -m snap -s data.seattle.gov:mags-97de
```

*navigate to an obe site, login and snap a picture*
```bash
$ ./snapper-caller.rb -m snap -s domain|OBE_4x4 -u <username> -p <password>
$ example: ruby snapper-caller.rb -m snap -s opendata-demo.rc-socrata.com:6q4t-m6c7 -u [SOCRATA_USER] -p [SOCRATA_PASSWORD]
```

*navigate to a site directly and snap a picture. -o is only used for taking snapshots.*
```bash
$ ./snapper-caller.rb -m snap -s url -o
$ example: ruby snapper-caller.rb -m snap -s http://www.socrata.com -o
```

*navigate to a publicly accessible (non-authenticated) site and take a snapshot of the DataLens page when no OBE page is available*
```bash
$ ./snapper-caller.rb -m snap -s url -o
$ example: ruby snapper-caller.rb -m snap -s https://data.cityofchicago.org/view/2bnm-jnvb
```

*navigate to a DataLens page, authenticate and take a picture (TBD)*


#### Diffing -
*navigate to two sites, compare and produce a diff of them.*

**In diff mode the tool is expecting the OBE 4x4 and will find the NBE 4x4 on its own**
```bash
$ ./snapper-caller.rb -m diff -s domain|OBE_4x4 -d domain:4x4
$ example: ruby snapper-caller.rb -m diff -s opendata-demo.rc-socrata.com:6q4t-m6c7 -d opendata-demo.rc-socrata.com:b5k5-ycfq
```

*navigate to two sites, login, compare and produce a diff of them.*

**in diff mode the tool is expecting the OBE 4x4 and will find the NBE 4x4 on its own**
```bash
$ ./snapper-caller.rb -m diff -s domain|OBE_4x4 -d domain:4x4  -u <username> -p <password>
$ example: ruby snapper-caller.rb -m diff -s opendata-demo.rc-socrata.com:6q4t-m6c7 -d opendata-demo.rc-socrata.com:b5k5-ycfq -u [SOCRATA_USER] -p [SOCRATA_PASSWORD]
```
