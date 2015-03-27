Instructions for using socrata-snapper
=====================================
page snap and comparison tool

The tool has the ability to navigate to, sign-in (in the case of Socrata sites) and take a snap shot of a web page. It also can look at the page for any javascript errors.

### Operations possibilities:
* navigate to a site and snap a picture
```bash
$ ruby snapper-caller.rb -m snap -s domain:4x4
```
* navigato to an obe site, login and snap a picture
```bash
$ ruby snapper-caller.rb -m snap -s domain:4x4 -u <username> -p <password>
```
* navigate to two sites, compare and produce a diff of them.
```bash
$ ruby snapper-caller.rb -m diff -s domain:4x4 -d domain:4x4
```
* navigate to two sites, login, compare and produce a diff of them.
```bash
$ ruby snapper-caller.rb -m diff -s domain:4x4 -d domain:4x4  -u <username> -p <password>
```

### order of operations
  1. goto site
  2. login if needed
  3. navigate to next location if needed
  4. snapshot the page and save it
  5. check for javascript errors if requested
  6. check for pageload errors if requested

### TODO:
* example of using tool to take diffs
* clarify requirements (do we need a page?)
