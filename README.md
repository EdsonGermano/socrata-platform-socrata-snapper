Instructions for using socrata-snapper
=====================================
page snap and comparison tool

The tool has the ability to navigate to, sign-in (in the case of Socrata sites) and take a snap shot of a web page. It also can look at the page for any javascript errors.

### Prerequisites
* run ```bundle install``` to install dependencies.

### Operations possibilities:
### PNG Snapping -
*navigate to a site and snap a picture when no authentication is required (public opendata sites)*
```bash
$ ./snapper-caller.rb -m snap --site1  domain#OBE_4x4
$ example: ruby snapper-caller.rb -m snap --site1 data.seattle.gov#mags-97de
```

*navigate to an obe site, login and snap a picture*
```bash
$ ./snapper-caller.rb -m snap --site1 domain#OBE_4x4 -u <username> -p <password>
$ example: ruby snapper-caller.rb -m snap --site1 opendata-demo.rc-socrata.com#6q4t-m6c7 -u [SOCRATA_USER] -p [SOCRATA_PASSWORD]
```

*navigate to a site directly and snap a picture. -o is only used for taking snapshots.*
```bash
$ ./snapper-caller.rb -m snap --site1 url -o
$ example: ruby snapper-caller.rb -m snap --site1  http://www.socrata.com -o
```

*navigate to a publicly accessible (non-authenticated) site and take a snapshot of the DataLens page when no OBE page is available*
```bash
$ ./snapper-caller.rb -m snap --site1 url -o
$ example: ruby snapper-caller.rb -m snap --site1  https://data.cityofchicago.org/view/2bnm-jnvb -o
```

*navigate directly to a DataLens page, authenticate and take a picture*
```bash
$ ./snapper-caller.rb -m snap --site1 url -u [SOCRATA_USER] -p [SOCRATA_PASSWORD] -o
$ example: ruby snapper-caller.rb -m snap --site1  https://dataspace.demo.socrata.com/view/8urc-6grh -o
```

#### Live Diffing -
*navigate to two sites that do not require authentication, compare and produce a diff of them.*

**In diff mode the tool is expecting the OBE 4x4 and will find the NBE 4x4 on its own**
```bash
$ ./snapper-caller.rb -m diff --site1 domain#OBE_4x4 --site2 domain#OBE_4x4
$ example: ruby snapper-caller.rb -m diff --site1 data.cityofchicago.org#ijzp-q8t2 -d data.cityofchicago.org#ijzp-q8t2
```

*navigate to two sites, login, compare and produce a diff of them.*

**in diff mode the tool is expecting the OBE 4x4 and will find the NBE 4x4 on its own**
```bash
$ ./snapper-caller.rb -m diff --site1  domain|OBE_4x4 --site2 domain#OBE_4x4 -u <username> -p <password>
$ example: ruby snapper-caller.rb -m diff --site1 opendata-demo.rc-socrata.com#6q4t-m6c7 -d opendata-demo.rc-socrata.com#b5k5-ycfq -u [SOCRATA_USER] -p [SOCRATA_PASSWORD]
```

#### File Comparison -
*given two *.png files, compare them and produce an output of their differences if the files are of the same size*

```bash
$ ./snapper-caller.rb -m compare_files -c <domain>#<full_path_to_png_1>#<full_path_to_png_2>
$ example: ruby snapper-caller.rb -m compare_files -c opdatata-demo.rc-socrata.com#/Users/joenunnelley/Developer/Socrata/socrata-snapper/logs/dataset_copy_6q4t-m6c7.png#/Users/joenunnelley/Developer/Socrata/socrata-snapper/logs/dataset_copy1_6q4t-m6c7.png
```

*given a csv file, compare the current site with a baseline*

```bash
$ ./snapper-caller.rb -m compare_files_csv -f <path to csv file>
$ example: ruby snapper-caller.rb -m compare_files_csv -f test_sites.csv
$ note: the csv file format is as follows:
$       https://dataspace.demo.socrata.com/view/e24t-fhrw, true
$       [URL, baseline latest snapshot |true|false|]  
```
