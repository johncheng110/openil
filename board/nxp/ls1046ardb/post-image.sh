#!/usr/bin/env bash
# args from BR2_ROOTFS_POST_SCRIPT_ARGS
# $2 linux building directory
# $3 buildroot top directory

main()
{
	local MKIMAGE=${HOST_DIR}/usr/bin/mkimage

	echo ${3}
	echo ${2}
	echo ${BR2_ROOTFS_PARTITION_SIZE}

	# cp the pre-build uboot mkimage to output/host/usr/bin
	cp board/nxp/ls1046ardb/temp/mkimage output/host/usr/bin
	rm -f board/nxp/ls1046ardb/temp/mkimage

	# cp the pre-build uboot and dtb images to output/images
	rm -f board/nxp/ls1046ardb/temp/Image
	cp board/nxp/ls1046ardb/temp/* output/images/

	# obtain the fman-ucode image
	tar zxf dl/fmucode-fsl-sdk-v2.0.tar.gz -C board/nxp/ls1046ardb/temp/
	cp board/nxp/ls1046ardb/temp/fmucode-fsl-sdk-v2.0/fsl_fman_ucode_ls1043_r1.0_108_4_5.bin output/images

	# build the itb image
	cp output/images/fsl-ls1046a-rdb.dtb ${2}/
	cp ${BINARIES_DIR}/rootfs.ext2.gz ${2}/fsl-image-core-ls1046ardb-32b.ext2.gz
	cd ${2}/
	${MKIMAGE} -f kernel-ls1046a-rdb-aarch32.its kernel-ls1046a-rdb-aarch32.itb
	cd ${3}
	cp ${2}/kernel-ls1046a-rdb-aarch32.itb ${BINARIES_DIR}/
	rm ${2}/fsl-image-core-ls1046ardb-32b.ext2.gz
	rm ${2}/fsl-ls1046a-rdb.dtb
	rm ${2}/kernel-ls1046a-rdb-aarch32.itb

	# build the ramdisk rootfs
	${MKIMAGE} -A arm -T ramdisk -C gzip -d ${BINARIES_DIR}/rootfs.ext2.gz ${BINARIES_DIR}/rootfs.ext2.gz.uboot

	# build the SDcard image
	local FILES=""kernel-ls1046a-rdb-aarch32.itb""
	local GENIMAGE_CFG="$(mktemp --suffix genimage.cfg)"
	local GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

	sed -e "s/%FILES%/${FILES}/" -e "s/%PARTITION_SIZE%/${BR2_ROOTFS_PARTITION_SIZE}/" \
		board/nxp/ls1046ardb/genimage.cfg.template > ${GENIMAGE_CFG}

	rm -rf "${GENIMAGE_TMP}"

	genimage \
		--rootpath "${TARGET_DIR}" \
		--tmppath "${GENIMAGE_TMP}" \
		--inputpath "${BINARIES_DIR}" \
		--outputpath "${BINARIES_DIR}" \
		--config "${GENIMAGE_CFG}"

	rm -f ${GENIMAGE_CFG}


	exit $?
}

main $@
