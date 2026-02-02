#!/bin/bash
# Show bookmark status for @-, closest bookmark, and trunk
echo "=== @- (parent commit) ==="
jj log --no-pager -r "@-" -T 'change_id.short() ++ " " ++ bookmarks ++ "\n"'

echo "=== closest_bookmark(@) ==="
jj log --no-pager -r "closest_bookmark(@)" -T 'change_id.short() ++ " " ++ bookmarks ++ "\n"'

echo "=== trunk() ==="
jj log --no-pager -r "trunk()" -T 'change_id.short() ++ " " ++ bookmarks ++ "\n"'
