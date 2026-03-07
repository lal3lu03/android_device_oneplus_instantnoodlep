#include <android-base/logging.h>
#include <hidl/HidlTransportSupport.h>

__attribute__((constructor)) static void ConfigureRpcThreadpoolCompat() {
    android::hardware::configureRpcThreadpool(1, true);
    LOG(INFO) << "Applied HIDL RPC threadpool compatibility shim";
}
