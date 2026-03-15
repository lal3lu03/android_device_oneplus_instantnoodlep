#!/vendor/bin/sh

# Recreate sensor persist/registry layout expected by init.vendor.sensors.rc.
PERSIST_DIR=/mnt/vendor/persist/sensors
REGISTRY_DIR=${PERSIST_DIR}/registry

mkdir -p ${REGISTRY_DIR}/registry
[ -e ${REGISTRY_DIR}/config ] || : > ${REGISTRY_DIR}/config
[ -e ${PERSIST_DIR}/sns.reg ] || : > ${PERSIST_DIR}/sns.reg
[ -e ${PERSIST_DIR}/sensors_list.txt ] || : > ${PERSIST_DIR}/sensors_list.txt
[ -e ${PERSIST_DIR}/sensors_settings ] || : > ${PERSIST_DIR}/sensors_settings
[ -e ${REGISTRY_DIR}/registry/sensors_registry ] || : > ${REGISTRY_DIR}/registry/sensors_registry
[ -e ${REGISTRY_DIR}/sns_reg_version ] || : > ${REGISTRY_DIR}/sns_reg_version

if [ -f /vendor/etc/sensors/sns_reg_config ]; then
    [ -e ${REGISTRY_DIR}/sns_reg_config ] || cp /vendor/etc/sensors/sns_reg_config ${REGISTRY_DIR}/sns_reg_config
else
    [ -e ${REGISTRY_DIR}/sns_reg_config ] || : > ${REGISTRY_DIR}/sns_reg_config
fi
