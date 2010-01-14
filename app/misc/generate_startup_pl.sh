cd lib
if [ $? = 0 ]
then
    find . -name '*.pm' | sed -e 's/\.\//use /' | sed -e 's/\//::/g' | sed -e 's/\.pm/;/' > ../startup.pl
    cd ..
fi
