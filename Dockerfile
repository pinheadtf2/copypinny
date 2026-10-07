ARG VARIANT=dj
ARG IMAGE_TAG=latest

FROM ghcr.io/9001/copyparty-${VARIANT}:${IMAGE_TAG}

ARG VARIANT

# Remove the H265- and non-LC-AAC-stripped FFmpeg and reinstall a normal,
# full-featured FFmpeg.
#
# For iv/dj, also reinstall vips-heif.
# For dj, keyfinder-cli is removed and then reinstalled because it depends
# on FFmpeg.
#
# libraw-tools provides dcraw_emu, which Copyparty can use for RAW photos.
RUN set -eux; \
    if [ "$VARIANT" = "dj" ]; then \
        apk del --no-network keyfinder-cli ffmpeg 'ffmpeg-*'; \
        apk add --no-cache \
            ffmpeg \
            keyfinder-cli \
            vips-heif \
            libraw-tools; \
    elif [ "$VARIANT" = "iv" ]; then \
        apk del --no-network ffmpeg 'ffmpeg-*'; \
        apk add --no-cache \
            ffmpeg \
            vips-heif \
            libraw-tools; \
    elif [ "$VARIANT" = "ac" ]; then \
        apk del --no-network ffmpeg 'ffmpeg-*'; \
        apk add --no-cache \
            ffmpeg \
            libraw-tools; \
    else \
        echo "Only dj/iv/ac variants have FFmpeg, no need to build anything else"; \
        exit 1; \
    fi; \
    \
    # Ensure the newly installed FFmpeg has H265 support.
    ffmpeg -hide_banner -decoders | \
        grep -qiE '^[[:space:]]*V.*[[:space:]]hevc[[:space:]]'; \
    \
    # Verify RAW support is actually available.
    # dcraw_emu exits 1 after printing usage, so only fail on "not runnable"
    # (127 = missing binary/library, 126 = not executable, >128 = crash).
    command -v dcraw_emu; \
    rc=0; \
    dcraw_emu -h >/dev/null 2>&1 || rc=$?; \
    [ "$rc" -le 1 ]
