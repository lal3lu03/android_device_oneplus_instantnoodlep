#!/vendor/bin/sh

# Recreate sensor persist/registry layout expected by init.vendor.sensors.rc.
PERSIST_DIR=/mnt/vendor/persist/sensors
REGISTRY_DIR=${PERSIST_DIR}/registry

mkdir -p ${REGISTRY_DIR}/registry
[ -e ${REGISTRY_DIR}/config ] || touch ${REGISTRY_DIR}/config
touch ${PERSIST_DIR}/sns.reg
touch ${PERSIST_DIR}/sensors_list.txt
touch ${PERSIST_DIR}/sensors_settings
touch ${REGISTRY_DIR}/registry/sensors_registry
touch ${REGISTRY_DIR}/sns_reg_version

if [ -f /vendor/etc/sensors/sns_reg_config ]; then
    cp -f /vendor/etc/sensors/sns_reg_config ${REGISTRY_DIR}/sns_reg_config
else
    touch ${REGISTRY_DIR}/sns_reg_config
fi

chmod 0664 ${PERSIST_DIR}/sensors_settings 2>/dev/null
