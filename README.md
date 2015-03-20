# socrata-snapper
page snap and comparison tool

The tool has the ability to navigate to, sign-in (in the case of Socrata sites) and take a snap shot of a web page. It also can look at the page for any javascript errors

Operation possibilities

1.) navigate to a site and snap a picture
    <script> -s domain:4x4 [-l <logdirectory>] [-o <logfilename>]

2.) navigato to a site, login and snap a picture
    <script> -s domain:4x4 -u <username> -p <password> [-l <logdirectory>] [-o <logfilename>]

3.) navigate to a site and examine for javascript errors
    <script> -s domain:4x4 -j [-l <logdirectory>] [-o <logfilename>]

4.) navigate to a site, login and examine for javascript errors
    <script> -s domain:4x4 -u <username> -p <password> -j [-l <logdirectory>] [-o <logfilename>]

5.) navigate to a site and examine for page errors (TBD)
    <script> -s domain:4x4 -p [-l <logdirectory>] [-o <logfilename>]

6.) navigate to a site, login and examine for page errors (TBD)
    <script> -s domain:4x4 -u <username> -p <password> -p [-l <logdirectory>] [-o <logfilename>]

7.) navigate to two sites, compare and produce a diff of them.
    <script> -s domain:4x4 -d domain:4x4 -c [-l <logdirectory>] [-o <logfilename>]

8.) navigate to two sites, login, compare and produce a diff of them.
    <script> -s domain:4x4 -d domain:4x4  -u <username> -p <password> -c [-l <logdirectory>] [-o <logfilename>]

9.)  navigate to two sites compare, produce diff and check for javascript and page errors
    <script> -s domain:4x4 -d domain:4x4 -c -j -p [-l <logdirectory>] [-o <logfilename>]

10.) navigate to two sites, login, compare, produce diff and check for javascript and page errors
    <script> -s domain:4x4 -d domain:4x4  -u <username> -p <password> -c -j -p [-l <logdirectory>] [-o <logfilename>]


#ruby snapper-caller.rb -s azure_rc:opendata-demo.test-socrata.com -d azure_staging:opendata-demo.test-socrata.com -u joe.nunnelley@socrata.com -p Und3rd0g -l logs -o snappit.png
#ruby snapper-caller.rb -s azure_rc:opendata-demo.test-socrata.com -4 b7hm-7vvu -d azure_staging:opendata-demo.test-socrata.com -u joe.nunnelley@socrata.com -p Und3rd0g -l logs -o snappit.png

order of operations

  1.) goto site
  2.) login if needed
  3.) navigate to next location if needed
  4.) snapshot the page and save it
  5.) check for javascript errors if requested
  6.) check for pageload errors if requested



Snaps to take

<domain>/browse
<domain>/d/<4x4>
<domain>/datasets <- must be logged in
<domain>/profile/<4x4>
<domain>/home
<domain>/login
<domain>/signup
<domain>/view/<4x4> <- new UX
<domain>/views/
