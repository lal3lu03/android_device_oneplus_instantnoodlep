#!/vendor/bin/sh

# Recreate sensor persist/registry layout expected by init.vendor.sensors.rc.
PATH=/vendor/bin:/odm/bin:/system/bin
export PATH

PERSIST_DIR=/mnt/vendor/persist/sensors
REGISTRY_DIR=${PERSIST_DIR}/registry
PROX_CAL_FILE=${REGISTRY_DIR}/registry/stk2232_0_platform.ps.fac_cal
LOG_TAG=sensor_recover
GOOD_OFFSET=300.000000
BAD_OFFSET_LIMIT=5000
RETRY_COUNT=90
RETRY_SLEEP_SEC=1

log_info() {
    /vendor/bin/log -t ${LOG_TAG} "$1"
}

ensure_registry_tree() {
    /vendor/bin/mkdir -p ${REGISTRY_DIR}/registry
    [ -e ${REGISTRY_DIR}/config ] || : > ${REGISTRY_DIR}/config
    [ -e ${PERSIST_DIR}/sns.reg ] || : > ${PERSIST_DIR}/sns.reg
    [ -e ${PERSIST_DIR}/sensors_list.txt ] || : > ${PERSIST_DIR}/sensors_list.txt
    [ -e ${PERSIST_DIR}/sensors_settings ] || : > ${PERSIST_DIR}/sensors_settings
    [ -e ${REGISTRY_DIR}/registry/sensors_registry ] || : > ${REGISTRY_DIR}/registry/sensors_registry
    [ -e ${REGISTRY_DIR}/sns_reg_version ] || : > ${REGISTRY_DIR}/sns_reg_version

    if [ -f /vendor/etc/sensors/sns_reg_config ]; then
        [ -e ${REGISTRY_DIR}/sns_reg_config ] || /vendor/bin/cp /vendor/etc/sensors/sns_reg_config ${REGISTRY_DIR}/sns_reg_config
    else
        [ -e ${REGISTRY_DIR}/sns_reg_config ] || : > ${REGISTRY_DIR}/sns_reg_config
    fi
}

# Guard against corrupted STK2232 proximity calibration persisted across slots.
# Bad offsets (for example ~19000) keep proximity stuck in FAR during calls.
sanitize_one_cal_file() {
    CAL_FILE="$1"
    if [ ! -f "${CAL_FILE}" ]; then
        return 1
    fi

    CAL_JSON=$(/vendor/bin/tr -d '[:space:]' < "${CAL_FILE}")
    OFFSET1=$(/vendor/bin/echo "${CAL_JSON}" | /vendor/bin/sed -n 's/.*"offset1":{[^}]*"data":"\([-0-9.]*\)".*/\1/p' | /vendor/bin/head -n 1)
    OFFSET2=$(/vendor/bin/echo "${CAL_JSON}" | /vendor/bin/sed -n 's/.*"offset2":{[^}]*"data":"\([-0-9.]*\)".*/\1/p' | /vendor/bin/head -n 1)
    OFFSET1_INT=${OFFSET1%%.*}
    OFFSET2_INT=${OFFSET2%%.*}

    if /vendor/bin/echo "${OFFSET1_INT}" | /vendor/bin/grep -Eq '^-?[0-9]+$' && /vendor/bin/echo "${OFFSET2_INT}" | /vendor/bin/grep -Eq '^-?[0-9]+$'; then
        OFFSET1_ABS=${OFFSET1_INT#-}
        OFFSET2_ABS=${OFFSET2_INT#-}
        if [ "${OFFSET1_ABS}" -gt "${BAD_OFFSET_LIMIT}" ] || [ "${OFFSET2_ABS}" -gt "${BAD_OFFSET_LIMIT}" ]; then
            BAD_SUFFIX=$(/vendor/bin/date +%s)
            /vendor/bin/cp "${CAL_FILE}" "${CAL_FILE}.bad.${BAD_SUFFIX}" 2>/dev/null
            /vendor/bin/sed -E -i 's/("offset1"[[:space:]]*:[[:space:]]*\{[^}]*"data"[[:space:]]*:[[:space:]]*")[^"]*(")/\1300.000000\2/' "${CAL_FILE}"
            /vendor/bin/sed -E -i 's/("offset2"[[:space:]]*:[[:space:]]*\{[^}]*"data"[[:space:]]*:[[:space:]]*")[^"]*(")/\1300.000000\2/' "${CAL_FILE}"
            /vendor/bin/chown system:system "${CAL_FILE}" 2>/dev/null
            /vendor/bin/chmod 0600 "${CAL_FILE}" 2>/dev/null
            log_info "normalized bad stk2232 offsets file=${CAL_FILE} offset1=${OFFSET1} offset2=${OFFSET2} -> ${GOOD_OFFSET}"
        fi
    else
        log_info "unable to parse stk2232 offsets in ${CAL_FILE}; leaving file unchanged"
    fi
    return 0
}

sanitize_prox_cal() {
    FOUND=0

    # Canonical filename (older devices/trees)
    if [ -f "${PROX_CAL_FILE}" ]; then
        FOUND=1
        sanitize_one_cal_file "${PROX_CAL_FILE}"
    fi

    # Newer/observed runtime files with dynamic suffixes, for example:
    # stk2232_0_platform.ps.fac_cal.pretest2.<timestamp>
    for CAL_FILE in ${REGISTRY_DIR}/registry/stk2232_0_platform.ps.fac_cal*; do
        [ -f "${CAL_FILE}" ] || continue
        FOUND=1
        sanitize_one_cal_file "${CAL_FILE}"
    done

    if [ "${FOUND}" -eq 0 ]; then
        return 1
    fi
    return 0
}

ensure_registry_tree
log_info "start uid=$(/vendor/bin/id -u)"

ITER=0
while [ "${ITER}" -lt "${RETRY_COUNT}" ]; do
    if sanitize_prox_cal; then
        exit 0
    fi
    ITER=$((ITER + 1))
    /vendor/bin/sleep "${RETRY_SLEEP_SEC}"
done

log_info "stk2232 calibration file not found after ${RETRY_COUNT}s"
exit 0
