chefdk_root="/opt/chefdk"
chefdk_bin_dir="${chefdk_root}/bin"
if [ -d "${chefdk_bin_dir}" ]; then
    export PATH="${chefdk_bin_dir}:$PATH"
fi
