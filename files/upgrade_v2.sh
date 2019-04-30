UPGRADE_PRE_V2=${UPGRADE_PRE_V2:-"FALSE"};

#
# Fix the repository locations in the archiva.xml 
# configuration from v2-legacy containers and force
# archiva to rescan and reindex all artifacts.
#
# note: this is a no-op if the archiva config doesn't
# need to be changed.
#
REPO_LOCATIONS_TO_FIX=$(grep "<location>./repositories/" "${ARCHIVA_BASE}/conf/archiva.xml" &2>&1)
if [ ! -z "$REPO_LOCATIONS_TO_FIX" ]
then
  if [ "$UPGRADE_PRE_V2" != "true" ]
  then
    echo 
    echo "================"
    echo "!! Potentially Destructive V2 Upgrade Necessary !!"
    echo
    echo "Some upgrade steps are necessary for your Archiva deployment. While this"
    echo "image can automatically perform these steps, they require removing some"
    echo "data which might be destructive to your deployment." 
    echo
    echo
    echo "Please see the section of the README titled 'Upgrading from tag 2.2.3 and earlier'"
    echo
    echo "  https://github.com/xetus-oss/docker-archiva#enable-configuration-migrations"
    echo
    echo
    echo "When ready to proceed with the upgrade, restart the container with"
    echo "the environment variable UPGRADE_PRE_V2 set to \"true\"."
    echo "For example:"
    echo
    echo "  docker run -d --name archiva \ "
    echo "                -v /host/path/archiva-data:/archiva-data \ "
    echo "                -e UPGRADE_PRE_V2=true \ "
    echo "                xetusoss/archiva:v2"
    echo
    echo "================"
    echo
    exit 1;
  fi

  echo "================"
  echo 
  echo "UPGRADE_PRE_V2 was set, performing required V2 image upgrade..."

  echo "Upgrading all relative paths in your Archiva configuation file to be absolute..."
  cat "${ARCHIVA_BASE}/conf/archiva.xml" | \
    sed -E 's@<(location|indexDir)>\./repositories/(.*)</(location|indexDir)>@<\1>/archiva-data/repositories/\2</\3>@' > \
      "${ARCHIVA_BASE}/conf/archiva.xml"

  if [ -e "${ARCHIVA_BASE}/data/jcr" ]
  then
    echo "Removing the JCR to avoid \"ghost artifacts\" in your Archiva UI..."
    rm -r "${ARCHIVA_BASE}/data/jcr"
  fi

  if [ -e "${ARCHIVA_BASE}/repositories/repositories" ]
  then
    echo "Removing ${ARCHIVA_BASE}/repositories/repositories, which contains old .indexer files..."
    rm -r "${ARCHIVA_BASE}/repositories/repositories"
  fi

  echo
  echo "Finished V2 image upgrade process."
  echo 
  echo "Archiva will need to re-scan and re-index all artifacts on startup, which may"
  echo "take a while."
  echo
  echo "================"
fi