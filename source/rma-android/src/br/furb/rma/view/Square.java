package br.furb.rma.view;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.util.List;

import javax.microedition.khronos.opengles.GL10;

import android.content.Context;
import android.graphics.Bitmap;
import android.opengl.GLUtils;
import br.furb.rma.models.Dicom;

public class Square {

	private Dicom dicom;
	private GL10 gl;
	private Context context;
	
	private FloatBuffer vertexBuffer;
	//private int[] textures = new int[1];
	private int[] textures;
	
	private List<Bitmap> bitmaps;

	private float vertices[] = {
			-1.0f, -1.0f,  0.0f,        // V1 - bottom left
			-1.0f,  1.0f,  0.0f,        // V2 - top left
			1.0f, -1.0f,  0.0f,        // V3 - bottom right
			1.0f,  1.0f,  0.0f         // V4 - top right
		};
	
	private FloatBuffer textureBuffer;	// buffer holding the texture coordinates
	private float texture[] = {    		
		// Mapping coordinates for the vertices
		0.0f, 1.0f,		// top left		(V2)
		0.0f, 0.0f,		// bottom left	(V1)
		1.0f, 1.0f,		// top right	(V4)
		1.0f, 0.0f		// bottom right	(V3)
	};
	
	public Square(Dicom dicom, List<Bitmap> bitmaps) {
		this.dicom = dicom;
		
		textures = new int[dicom.getImages().size()];
		this.bitmaps = bitmaps;
		
		ByteBuffer byteBuffer = ByteBuffer.allocateDirect(vertices.length * 4); 
		byteBuffer.order(ByteOrder.nativeOrder());
		vertexBuffer = byteBuffer.asFloatBuffer();
		vertexBuffer.put(vertices);
		vertexBuffer.position(0);

		byteBuffer = ByteBuffer.allocateDirect(texture.length * 4);
		byteBuffer.order(ByteOrder.nativeOrder());
		textureBuffer = byteBuffer.asFloatBuffer();
		textureBuffer.put(texture);
		textureBuffer.position(0);
	}
	
	public void draw(GL10 gl) {
		gl.glMatrixMode(GL10.GL_MODELVIEW);
		
		/*gl.glEnableClientState(GL10.GL_VERTEX_ARRAY);
		gl.glColor4f(0.0f, 1.0f, 0.0f, 0.5f);
		gl.glVertexPointer(3, GL10.GL_FLOAT, 0, vertexBuffer);
		gl.glDrawArrays(GL10.GL_TRIANGLE_STRIP, 0, vertices.length / 3);
		gl.glDisableClientState(GL10.GL_VERTEX_ARRAY);*/

		float y = -0.01f;
		float inc = y;
		
		gl.glEnable(GL10.GL_TEXTURE_2D);
		
		for (int i = 0; i < textures.length; i++) {
			gl.glTranslatef(0.0f, y, 0.0f);
			
			// bind the previously generated texture
			gl.glBindTexture(GL10.GL_TEXTURE_2D, textures[i]);

			// Point to our buffers
			gl.glEnableClientState(GL10.GL_VERTEX_ARRAY);
			gl.glEnableClientState(GL10.GL_TEXTURE_COORD_ARRAY);

			// Set the face rotation
			gl.glFrontFace(GL10.GL_CW);

			// Point to our vertex buffer
			gl.glVertexPointer(3, GL10.GL_FLOAT, 0, vertexBuffer);
			gl.glTexCoordPointer(2, GL10.GL_FLOAT, 0, textureBuffer);

			// Draw the vertices as triangle strip
			gl.glDrawArrays(GL10.GL_TRIANGLE_STRIP, 0, vertices.length / 3);
			
			y += inc;
		}

		// Disable the client state before leaving
		gl.glDisableClientState(GL10.GL_VERTEX_ARRAY);
		gl.glDisableClientState(GL10.GL_TEXTURE_COORD_ARRAY);
	}
	
	public void loadGLTexture(GL10 gl, Context context, Bitmap bitmap) {
		// generate one texture pointer
		gl.glGenTextures(1, textures, 0);
		// ...and bind it to our array
		gl.glBindTexture(GL10.GL_TEXTURE_2D, textures[0]);
		
		// create nearest filtered texture
		gl.glTexParameterf(GL10.GL_TEXTURE_2D, GL10.GL_TEXTURE_MIN_FILTER, GL10.GL_NEAREST);
		gl.glTexParameterf(GL10.GL_TEXTURE_2D, GL10.GL_TEXTURE_MAG_FILTER, GL10.GL_LINEAR);
		
		gl.glTexParameterf(GL10.GL_TEXTURE_2D, GL10.GL_TEXTURE_WRAP_S, GL10.GL_REPEAT);
		gl.glTexParameterf(GL10.GL_TEXTURE_2D, GL10.GL_TEXTURE_WRAP_T, GL10.GL_REPEAT);
		
		// Use Android GLUtils to specify a two-dimensional texture image from our bitmap 
		GLUtils.texImage2D(GL10.GL_TEXTURE_2D, 0, bitmap, 0);
		
		// Clean up
		//bitmap.recycle();
	}
	
	public void loadGLTextureNew(GL10 gl, Context context) {
		Bitmap bitmap = null;
		gl.glGenTextures(textures.length, textures, 0);
		float y = -0.1f;
		
		for (int i = 0; i < textures.length; i++) {
			// generate one texture pointer
			
			//gl.glTranslatef(0.0f, y, -5.0f);
			
			// ...and bind it to our array
			gl.glBindTexture(GL10.GL_TEXTURE_2D, textures[i]);
			
			// create nearest filtered texture
			gl.glTexParameterf(GL10.GL_TEXTURE_2D, GL10.GL_TEXTURE_MIN_FILTER, GL10.GL_NEAREST);
			gl.glTexParameterf(GL10.GL_TEXTURE_2D, GL10.GL_TEXTURE_MAG_FILTER, GL10.GL_LINEAR);
			
			gl.glTexParameterf(GL10.GL_TEXTURE_2D, GL10.GL_TEXTURE_WRAP_S, GL10.GL_REPEAT);
			gl.glTexParameterf(GL10.GL_TEXTURE_2D, GL10.GL_TEXTURE_WRAP_T, GL10.GL_REPEAT);
			
			// Use Android GLUtils to specify a two-dimensional texture image from our bitmap
			bitmap = bitmaps.get(i);
			GLUtils.texImage2D(GL10.GL_TEXTURE_2D, 0, bitmap, 0);
			gl.glBindTexture(GL10.GL_TEXTURE_2D, 0);
			
			y += -0.1f;
		}
		
		// Clean up
		//bitmap.recycle();
	}
	
	public Dicom getDicom() {
		return dicom;
	}
	
}
