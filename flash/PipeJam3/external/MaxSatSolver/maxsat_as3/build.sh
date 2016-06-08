if [ "$1" = "clean" ]; then
    rm -f *~
fi

cd util; bash build.sh $@; cd ..
cd worker; bash build.sh $@; cd ..
cd manager; bash build.sh $@; cd ..
