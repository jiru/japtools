
video_grinder
=============

Allows to extract audio samples from a batch of videos, given a list of starting and ending timestamps.

How to use
----------

1. Write your local config (see the Makefile for more options).
        echo "VIDEOS_DIR = /path/to/videos" > Makefile.local

2. Prepare a timestamps file with the videos file names.
        ls /path/to/videos/awsome/series/ > ./Series.timestamps.txt

3. Add your timestamps for each video (see the existing samples)
        vim ./Series.timestamps.txt

4. Generate audio extracts from these timestamps to the folder Series/.
        make Series/

