#!/bin/sh

curl 'https://bugzilla.mozilla.org/rest/bug?keywords=DevAdvocacy&include_fields=id,summary,status,resolution,is_open,dupe_of,keywords,whiteboard,product,component,creator,creator_detail,creation_time,last_change_time' > DATA_SNAPSHOT.json
