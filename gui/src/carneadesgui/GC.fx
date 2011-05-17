/*
Carneades Argumentation Library and Tools.
Copyright (C) 2008 Matthias Grabmair

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 3 (GPL-3)
as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

package carneadesgui;

import javafx.geometry.HPos;
import javafx.geometry.VPos;
import javafx.scene.Group;
import javafx.scene.Node;
import javafx.scene.effect.Effect;
import javafx.scene.effect.Glow;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Color;
import javafx.scene.shape.Rectangle;
import javafx.scene.shape.Circle;
import java.lang.Object;
import java.lang.System;
import javafx.scene.CustomNode;
import javafx.scene.text.Font;
import javafx.scene.text.Text;
import javafx.scene.text.TextAlignment;
import javafx.scene.text.TextOrigin;
import javafx.scene.paint.Paint;


// Model Constants
public def proofStandardSE: String = "scintilla of evidence";
public def proofStandardDV: String = "dialectical validity";
public def proofStandardPE: String = "preponderance";
public def proofStandardCCE: String = "clear and convincing";
public def proofStandardBRD: String = "beyond reasonable doubt";

// General Application Constants
public var APP_WIDTH: Number = 850;
public var APP_HEIGHT: Number = 600;
public def VERTICAL_WINDOW_MISMATCH: Number = 23;
public def HORIZONTAL_WINDOW_MISMATCH: Number = 1;

// StandardView Constants
public var MAINPANEL_SPACING: Integer = 1;	// spacing between the two/three main panels

// Graph Display Constants

// Drawing constants
public var DEFAULT_BOX_FILL: Color = Color.WHITE;
public var DRAW_DEBUG_INFO = bind debug;
public var VIEW_BACKGROUND_COLOR: Color = Color.rgb(178, 195, 218);
public var TOOLPANEL_BACKGROUND_COLOR: Color = Color.rgb(124, 141, 172);
public var PANEL_BACKGROUND_COLOR: Color = Color.rgb(223, 226, 229);

// Image Export Constants
public var IMAGE_EXPORT_BACKGROUND: Color = Color.WHITE;

public var edgeStrokeWidth: Number = 1;
public var selectionColor: Color = Color.RED;
public var hoverColor: Color = Color.ORANGE;
public var dragColor: Color = Color {
    red: 0.5
    green: 0
    blue: 0
    opacity: 0.5
};
public var possibleColor: Color = Color.GREEN;
public var impossibleColor: Color = Color.RED;

public var edgeSelectionWidth: Integer = 5;
public var selectedEdgeWidth: Integer = 3;

// Zooming
public var zoomTime: Number = 4.0; // in seconds
public var zoomLimits: Number[] = [0.2, 3.0];
public var ZOOM_INCREMENT: Number = 0.05;

// Statement Boxes
public var statementBoxDefaultWidth: Integer = 150;
public var statementBoxDefaultHeight: Integer = 50;
public var statementBoxBottomBrink: Integer = 40;
public var statementBoxTextHorizontalPadding: Number = 10;
public var STATEMENTBOX_FONTSIZE: Integer = 12;
public var STATEMENTBOX_TEXT_NUMLINES: Integer = 3;
public var STATEMENTBOX_TEXT_MAXCHARINLINE: Integer = 18;
public var STATEMENTBOX_TEXT_HOR_HANDCOR: Integer = -3;

public var fillStatements = true;
public var statusAcceptedColor: Color = Color.rgb(45, 193, 56);
public var statusRejectedColor: Color = Color.rgb(255, 82, 85);
public var statusAssumedTrueColor: Color = Color.rgb(45, 193, 56); // Color.rgb(106, 255, 121);
public var statusAssumedFalseColor: Color = Color.rgb(255, 82, 85); //old: Color.rgb(193, 160, 164);
public var statusStatedColor: Color = Color.WHITE;
public var statusQuestionedColor: Color = Color.rgb(255, 251, 144);

public var displayAcceptableCircles: Boolean = true;
public var acceptableCircleWidth: Integer = 15;
public var acceptableCirclePadding: Integer = 5;

// Argument Boxes. They were originally boxes, hence the name.
public var argumentBoxDefaultWidth: Integer = 60;
public var argumentBoxBottomBrink: Integer = 15;
public var argumentCircleDefaultRadius: Integer = 20;
public var argumentConColor = statusRejectedColor;
public var argumentProColor = statusAcceptedColor;

// Graphic Export constants
public var SVG_SCALING_FACTOR: Number = 3;
public var SVG_LEFTOFFSET: Integer = 50;
public var SVG_CREATE_PNG: Boolean = false;

// toolbar constants
public var toolBarHeight: Integer = 60;
public var toolBarSpacing: Integer = 10;

// MoveablePanel
public def MOVEABLEPANEL_TITLE_HEIGHT = 20;
public def MOVEABLEPANEL_TITLE_FILL = Color.PURPLE;
public def MOVEABLEPANEL_TITLE_EFFECT: Effect = Glow {}

// inspector panel constants
public def INSPECTOR_PANEL_MOVEABLE: Boolean = false;
public def SIDEBAR_SPACING: Integer = 10;
public def INSPECTOR_PANEL_SPACING: Integer = 5;
public def INSPECTOR_PANEL_HEIGHT: Integer = 295;
public def INSPECTOR_PADDING: Integer = 5;
public def INSPECTOR_WINDOWEDGE_PADDING: Number = 5;
public var inspectorPanelWidth: Integer = 280;
public var inspectorLabelWidth: Integer = 100;
public var inspectorDefaultMode: Integer = 0;
public var inspectorStatementMode: Integer = 1;
public var inspectorArgumentMode: Integer = 2;
public var inspectorPremiseMode: Integer = 3;
public var inspectorGraphMode: Integer = 4;

// Graph List mode constants
public def GRAPHLISTVIEW_MOVEABLE: Boolean = false;
public var listGraphMode: Integer = 1;
public var listStatementMode: Integer = 2;
public var listArgumentMode: Integer = 3;
public var GRAPHLISTVIEW_HEIGHT: Integer = 160;
public var GRAPHLISTVIEW_MINIMIZED_HEIGHT: Integer = 35;
public var GRAPHLISTVIEW_SPACING: Number = 3;
public var listEntryFieldHeight: Integer = 20;
public var tabButtonHeight: Integer = 25;

// Edit button panel constants
public var editButtonPanelHeight: Integer = 25 + 2*INSPECTOR_PADDING;

// User interaction constants
public var controlsLocked: Boolean = false;
public var idsEditable: Boolean = true;

// Version administration constants
public var debug: Boolean = false;

// Graph Layout constants

// General Vertex Constants
public var scaleVerticesWithText = false;
public var vertexDefaultWidth: Integer = 50;
public var vertexDefaultHeight: Integer = 40;

// The horizontal distance between neighboring tree nodes.
public var xPadding: Integer = 10;

// The vertical distance between the layers of the tree.
public var yPadding: Integer = 50;



// Graph validation constants

/**
 * Constant for functions to return if their operation performed valid.
 */
public var AG_OK: Number = 1;

/**
 * Constant for validation functions to return if graph contains a cycle.
 */
public var AG_CYCLE: Number = 2;

/**
 * Constants for validation functions to return if graph contains a double id.
 */
public var AG_DOUBLE_ID: Number = 3;

// Command execution constants

/**
 * Constant for commands to return if their execution was successful.
 */
public var C_OK: Number = 0;

/**
 * Constant for commands to return if their execution was not successful.
 */
public var C_ERROR: Number = 1;

/**
 * Constant for commands to return if no undo is possible.
 */
public var C_NO_UNDO: Number = 2;

/**
 * Constants for commands if no further redo is possible.
 */
public var C_LATEST_COMMAND: Number = 3;

// helper functions

/**
 * Shortcut print function for debug purposes.
 */
public var p = function(s: String) { System.out.println(s)}

public def flag = Circle {
	centerX: 0
	centerY: 0
	radius: 5
	fill: Color.PINK
	onMouseClicked: function(e:MouseEvent): Void {
		p("c");
	}
}

public class Filler extends Text {
	public var text = "This \nis a \ntotally cool \nfiller text...";

	override var textAlignment = TextAlignment.LEFT;
	override var textOrigin = TextOrigin.TOP;
	override var font = Font { size: 12 };
	override var content = bind text;
}

public class LayoutRect extends Rectangle {
	override var x = 0;
	override var y = 0;
	override var width = bind parent.layoutBounds.width;
	override var height = bind parent.layoutBounds.height;
	override var fill = bind Color.RED;
	//override var stroke = Color.YELLOW;
}

public function isMemberOf(object: Object, sequence: Object[]): Boolean {
    for (e in sequence) if (e == object) return true;
    false
}

// function that returns the position (1+) of an object in a sequence. If it is not in there, it returns 0;
public function indexOf(object: Object, list: Object[]): Integer {
	for (i in [0..sizeof list - 1]) if (object == list[i]) return i + 1;
	return 0
}

public class PaddedVBox extends CustomNode {

	public var xPadding: Number;
	public var yPadding: Number;
	public var spacing: Number;
	public var nodeHPos: HPos;
	public var hpos: HPos;

	public var content: Node[];

	override function create() {
		HBox {
			layoutInfo: bind layoutInfo
			spacing: bind xPadding
			content: bind [
				Rectangle {},
				VBox {
					nodeHPos: bind nodeHPos
					hpos: bind hpos
					spacing: bind yPadding
					content: bind [
						Rectangle {},
						VBox {
							nodeHPos: bind nodeHPos
							hpos: bind hpos
							spacing: bind spacing
							content: bind content
						}
						Rectangle {}
					]
				}
				Rectangle {}
			]
		}

	}
}

public class PaddedHBox extends CustomNode {

	public var xPadding: Number;
	public var yPadding: Number;
	public var spacing: Number;
	public var nodeVPos: VPos;

	public var content: Node[];

	override function create() {
		HBox {
			spacing: bind xPadding
			content: bind [
				Rectangle {},
				VBox {
					spacing: bind yPadding
					content: bind [
						Rectangle {},
						HBox {
							nodeVPos: bind nodeVPos
							spacing: bind spacing
							content: bind content
						}
						Rectangle {}
					]
				}
				Rectangle {}
			]
		}

	}
}

public class PaddedBox extends CustomNode {

	public var xPadding: Number;
	public var yPadding: Number;

	public var content: Node[];

	override function create() {
		HBox {
			spacing: bind xPadding
			content: bind [
				Rectangle {},
				VBox {
					spacing: bind yPadding
					content: bind [
						Rectangle {},
						Group {
							content: bind content
						}
						Rectangle {}
					]
				}
				Rectangle {}
			]
		}

	}
}

public function toSVGColorCode(p: Paint): String {
	var c: Color = p as Color;
	"#{Integer.toHexString(c.red*255)}{Integer.toHexString(c.green * 255)}{Integer.toHexString(c.blue * 255)}"
}

public bound function boundMin(a: Number, b: Number): Number {
		java.lang.Math.min(a, b)
}

// Statement Box line formatting
public function toLines(t: String): String[] {
	var words: String[] = t.split(" ");
	var lines: String[] = [];
	var currentLine: String = "";

	while (sizeof words > 0 and (sizeof lines < STATEMENTBOX_TEXT_NUMLINES)) {
		// Is the current word longer than the line break the word
		if (STATEMENTBOX_TEXT_MAXCHARINLINE < words[0].length()) {
			var firstHalf: String = "{words[0].substring(0, STATEMENTBOX_TEXT_MAXCHARINLINE - 2)}-";
			var secondHalf: String = "{words[0].substring(STATEMENTBOX_TEXT_MAXCHARINLINE-2, words[0].length())}";
			delete words[0] from words;
			words = [firstHalf, secondHalf, words];
		}

		// can we fit another word on the current line?
		if (currentLine.length() + words[0].length() + 1 <= STATEMENTBOX_TEXT_MAXCHARINLINE)
			{
				// if so, do it
				currentLine = "{currentLine} {words[0]}";
				delete words[0] from words;
				if (sizeof words == 0) insert currentLine into lines;
			}
		else {
			// add line
			insert currentLine into lines;
			currentLine = "";
		}
	}
	lines
}

public function toEscapeLines(t: String): String {
	var text: String = "";
	for (l in toLines(t)) text = "{text}{l}\n";
	text;
}
