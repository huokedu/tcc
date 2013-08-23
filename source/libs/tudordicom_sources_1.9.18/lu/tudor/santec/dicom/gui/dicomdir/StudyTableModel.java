package lu.tudor.santec.dicom.gui.dicomdir;

/*****************************************************************************
 *                                                                           
 *  Copyright (c) 2006 by SANTEC/TUDOR www.santec.tudor.lu                   
 *                                                                           
 *                                                                           
 *  This library is free software; you can redistribute it and/or modify it  
 *  under the terms of the GNU Lesser General Public License as published    
 *  by the Free Software Foundation; either version 2 of the License, or     
 *  (at your option) any later version.                                      
 *                                                                           
 *  This software is distributed in the hope that it will be useful, but     
 *  WITHOUT ANY WARRANTY; without even the implied warranty of               
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        
 *  Lesser General Public License for more details.                          
 *                                                                           
 *  You should have received a copy of the GNU Lesser General Public         
 *  License along with this library; if not, write to the Free Software      
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA  
 *                                                                           
 *****************************************************************************/

import java.util.Collections;
import java.util.Comparator;
import java.util.Vector;

import javax.swing.table.AbstractTableModel;

import lu.tudor.santec.i18n.Translatrix;

import org.dcm4che2.data.DicomObject;
import org.dcm4che2.data.Tag;

/**
 * @author Johannes Hermen johannes.hermen(at)tudor.lu
 *
 */
public class StudyTableModel extends AbstractTableModel  implements DicomTableModel{

	private static final long serialVersionUID = 1L;

	private String[] columns = {
			Translatrix.getTranslationString("dicom.StudyDesc"),
			Translatrix.getTranslationString("dicom.Date"),
			Translatrix.getTranslationString("dicom.Time")};
	private Vector<DicomObject> studies = new Vector<DicomObject>();

	public int getRowCount() {
		return studies.size();
	}

	public int getColumnCount() {
		return columns.length;
	}

	public String getColumnName(int column) {
		return columns[column];
	}

	public Object getValueAt(int rowIndex, int columnIndex) {
		try {
			if (rowIndex <= -1)
				return null;
			DicomObject dr = ((DicomObject) studies.get(rowIndex));
			switch (columnIndex) {
			case 0:
				return dr.getString(Tag.StudyDescription);
			case 1:
				return dr.getDate(Tag.StudyDate);
			case 2:
				return dr.getDate(Tag.StudyTime);
			default:
				return null;
			}		
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}
	
	public void setStudies(Vector<DicomObject> studies) {
		this.studies = studies;
		Collections.sort(this.studies, new Comparer());
		this.fireTableDataChanged();
	}

	public DicomObject getRecord(int line) {
		try {
			return (DicomObject) studies.get(line);	
		} catch (Exception e) {
			return null;
		}
		
	}
	
	class Comparer implements Comparator<DicomObject> {
        public int compare(DicomObject ds1, DicomObject ds2)
        {
        	try {
        		if (ds1.getDate(Tag.StudyDate).before(ds2.getDate(Tag.StudyDate)))
        			return 1;
        		else if (ds1.getDate(Tag.StudyDate).after(ds2.getDate(Tag.StudyDate))) 
        			return -1; 
        		else {
        			if (ds1.getDate(Tag.StudyTime).before(ds2.getDate(Tag.StudyTime)))
        				return 1;
        			else
        				return -1;
        		}				
			} catch (Exception e) {
				return -1;
			}
        }
	}
}
