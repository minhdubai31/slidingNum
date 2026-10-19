package com.minhth.slidepuzzle.imagepicker;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.webkit.MimeTypeMap;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.HashSet;
import java.util.Set;

// Opens the system image chooser (Photos / gallery) and copies the chosen picture into the app cache.
public class ImagePickerPlugin extends GodotPlugin {
	private static final int REQUEST_PICK = 7301;
	private final SignalInfo pickedSignal = new SignalInfo("image_picked", String.class);

	public ImagePickerPlugin(Godot godot) {
		super(godot);
	}

	@Override
	public String getPluginName() {
		return "ImagePicker";
	}

	@Override
	public Set<SignalInfo> getPluginSignals() {
		Set<SignalInfo> signals = new HashSet<>();
		signals.add(pickedSignal);
		return signals;
	}

	@UsedByGodot
	public void pick_image() {
		Activity activity = getActivity();
		if (activity == null) {
			return;
		}
		Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
		intent.setType("image/*");
		intent.addCategory(Intent.CATEGORY_OPENABLE);
		activity.startActivityForResult(intent, REQUEST_PICK);
	}

	@Override
	public void onMainActivityResult(int requestCode, int resultCode, Intent data) {
		if (requestCode != REQUEST_PICK || resultCode != Activity.RESULT_OK || data == null || data.getData() == null) {
			return;
		}
		String path = copyToCache(data.getData());
		if (path != null) {
			emitSignal(pickedSignal, path);
		}
	}

	private String copyToCache(Uri uri) {
		Activity activity = getActivity();
		if (activity == null) {
			return null;
		}
		String mime = activity.getContentResolver().getType(uri);
		String extension = mime == null ? null : MimeTypeMap.getSingleton().getExtensionFromMimeType(mime);
		if (extension == null) {
			extension = "jpg";
		}
		File target = new File(activity.getCacheDir(), "picked_picture." + extension);
		try (InputStream in = activity.getContentResolver().openInputStream(uri); OutputStream out = new FileOutputStream(target)) {
			if (in == null) {
				return null;
			}
			byte[] buffer = new byte[65536];
			int read;
			while ((read = in.read(buffer)) != -1) {
				out.write(buffer, 0, read);
			}
		} catch (IOException error) {
			return null;
		}
		return target.getAbsolutePath();
	}
}
