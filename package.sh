#!/bin/env bash

set -e

maintainer='E-Control Systems <info@econtrolsystems.com>'
pkgname='ptouch-print'
pkgver=""
pkgrel=1
pkgdesc='CLI to print labels on Brother P-Touch'
arch="$(dpkg --print-architecture)"
section=utils
license='GPL-3.0'
depends=(
    'printer-driver-ptouch'
    'libusb-1.0-0'
    'libgd3'
    'gettext'
)
makedepends=(
    'checkinstall'
    'libusb-1.0-0-dev' 
    'libgd-dev' 
    'git'
    'cmake' 
    'make' 
    'gcc'
    'gettext'
    'printer-driver-ptouch'
)

if [ -z $DIST_CODENAME ] 
then 
    source /etc/os-release
    DIST_CODENAME=$VERSION_CODENAME
fi

src="https://git.familie-radermacher.ch/linux/ptouch-print.git"

src_dir='src'
build_dir='build'

output_archive=''
output_deb=''

prepare() {
	rm -rf "${src_dir}"
    git clone --recurse-submodules "${src}" "${src_dir}"
    cd "${src_dir}"
    latest_tag=$(git describe --tags "$(git rev-list --tags --max-count=1)")
    git checkout "${latest_tag}"
}

version(){
    cd "${src_dir}"
    latest_tag=$(git describe --tags "$(git rev-list --tags --max-count=1)")
    semver=`echo "${latest_tag}" | grep --only-matching -E "[0-9.]+"`
    echo "${semver}"
}

build() {
    rm -rf "${build_dir}"
    cmake -B "${build_dir}"
    cmake --build "${build_dir}"
}

package_tar() {
    export temp_dir="$(mktemp -d)"
    (
        cd build
        make DESTDIR="${temp_dir}" install || true
    )
    export INSTALLER="install.sh"
    export UNINSTALLER="uninstall-ptouch-print"

    cat <<'EOF' > "${temp_dir}/usr/bin/${UNINSTALLER}"
#!/bin/sh
if [ $(/usr/bin/id -u) -ne 0 ]; then
    echo "Please rerun the script as root"
    exit
fi
EOF
    chmod +x "${temp_dir}/usr/bin/${UNINSTALLER}"
    cp -p "${temp_dir}/usr/bin/${UNINSTALLER}" "${temp_dir}/${INSTALLER}"

    (
        cd "${temp_dir}"
        find * -type f -not -name "${INSTALLER}" -exec sh -c "echo rm /{} >> ./usr/bin/${UNINSTALLER}" \;
        echo "udevadm control --reload-rules" >> ./usr/bin/${UNINSTALLER}


        find * -type d -exec sh -c "echo mkdir -p /{} >> ${INSTALLER}" \;
        find * -type f -not -name "${INSTALLER}" -exec sh -c "echo cp -p ./{} /{} >> ${temp_dir}/${INSTALLER}" \;
        echo "udevadm control --reload-rules" >> "${temp_dir}/${INSTALLER}"
    )

    
    tar -C "${temp_dir}" -czvf "${output_archive}" .

    rm -rf ${temp_dir}
}

package_deb() {
    cd ${build_dir}
    
    exclude="$(realpath ../po/ptouch.pot)"
    echo "${pkgdesc}" > description-pak
    sudo checkinstall -D -y \
    --install=yes \
    --fstrans=no \
    --pkgname=${pkgname} \
    --pkgversion=${pkgver} \
    --pkgsource=${src} \
    --pkgarch=${arch} \
    --pakdir="../" \
    --pkgrelease=${pkgrel} \
    --pkggroup=${section} \
    --pkglicense=${license} \
    --maintainer="'${maintainer}'" \
    --requires="'$(IFS=,; echo "${depends[*]}")'" \
    --reset-uids=yes \
    --delspec=yes \
    --deldoc=yes \
    --exclude="${exclude}"
    sudo apt purge --auto-remove ptouch-print -y

    cp "../${pkgname}_${pkgver}-${pkgrel}_${arch}.deb" "../${output_deb}"
}

postpackage() {
    cp ${src_dir}/${output_archive} .
    cp "${src_dir}/${output_deb}" .

    sudo rm -rf "${src_dir}"
}


main(){
    sudo apt install -y ${makedepends[*]}

    (prepare)
    pkgver=$(version)
    output_archive="${pkgname}-${pkgver}-linux-${DIST_CODENAME}-${arch}.tar.gz"
    output_deb="${pkgname}_${pkgver}-${pkgrel}+${DIST_CODENAME}_${arch}.deb"

    pushd ${src_dir}
    
    (build)
    (package_tar)
    (package_deb)

    popd

    (postpackage)
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
