package com.tidesworn.protectbesut.hms;

import android.graphics.Bitmap;
import com.huawei.hms.hmsscankit.ScanUtil;
import com.huawei.hms.ml.scan.HmsBuildBitmapOption;
import com.huawei.hms.ml.scan.HmsScan;
import java.io.ByteArrayOutputStream;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

/** Local-only QR generation. Does not start camera, activities or account flows. */
public final class ProtectBesutHms extends GodotPlugin {
    public ProtectBesutHms(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return "ProtectBesutHms";
    }

    @UsedByGodot
    public byte[] generate_qr(String content, int size) {
        if (content == null || content.isEmpty() || content.length() > 256
                || size < 128 || size > 1024) {
            return new byte[0];
        }
        Bitmap bitmap = null;
        try {
            ScanUtil.setOperationTrackingEnabled(false);
            HmsBuildBitmapOption options = new HmsBuildBitmapOption.Creator()
                    .setBitmapMargin(4).create();
            bitmap = ScanUtil.buildBitmap(content, HmsScan.QRCODE_SCAN_TYPE, size, size, options);
            if (bitmap == null) {
                return new byte[0];
            }
            ByteArrayOutputStream output = new ByteArrayOutputStream();
            if (!bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)) {
                return new byte[0];
            }
            return output.toByteArray();
        } catch (Exception | LinkageError failure) {
            // No fallback barcode: the UI must report an unavailable SDK honestly.
            return new byte[0];
        } finally {
            if (bitmap != null) {
                bitmap.recycle();
            }
        }
    }
}
