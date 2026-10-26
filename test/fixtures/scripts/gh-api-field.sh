#!/bin/sh
# gh api turns into a POST when it is given fields without -X GET
gh api repos/o/r/issues -f title=x
