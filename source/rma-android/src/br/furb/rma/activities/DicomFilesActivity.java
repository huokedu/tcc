package br.furb.rma.activities;

import java.io.File;
import java.io.FileFilter;
import java.util.ArrayList;
import java.util.List;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Message;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ListView;
import br.furb.rma.R;
import br.furb.rma.adapters.DicomFileAdapter;
import br.furb.rma.models.Dicom;

public class DicomFilesActivity extends Activity {

	public final static int ADD_ITEM = 0;
	
	private ListView listView;
	private DicomFileAdapter adapter;
	private boolean loadFiles = false;
	private Handler handler;
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.dicom_files_activity);
		
		listView = (ListView) findViewById(R.files.list);
		
		init();
		
		loadFiles();
	}

	private void init() {
		handler = new Handler() {
			@Override
			public void handleMessage(Message msg) {
				super.handleMessage(msg);
				
				if(msg.what == ADD_ITEM) {
					adapter.addItem((Dicom) msg.obj);
				}
			}
		};
		
		listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {

			@Override
			public void onItemClick(AdapterView<?> adapter, View view, int position, long id) {
				Intent it = new Intent(DicomFilesActivity.this, ViewerActivity.class);
				Bundle extras = new Bundle();
				Dicom dicom = (Dicom) adapter.getItemAtPosition(position);
				extras.putString("dir", dicom.getFile().getAbsolutePath());
				it.putExtras(extras);
				startActivity(it);
			}
		});
	}

	private void loadFiles() {
		List<Dicom> files = new ArrayList<Dicom>();
		files.add(new Dicom(new File(Environment.getExternalStorageDirectory().getAbsolutePath() + "/joelho_dalton")));
		
		adapter = new DicomFileAdapter(this);
		for (Dicom dicom : files) {
			adapter.addItem(dicom);
		}
		listView.setAdapter(adapter);
	}

}
