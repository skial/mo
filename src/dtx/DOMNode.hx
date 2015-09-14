/****
* Copyright (c) 2013 Jason O'Neil
*
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*
****/

package dtx;

/**
	A generic DOM Node. This is an abstract that wraps the underlying XML/DOM type for each platform.

	On Javascript, this wraps `js.html.Node` and forwards most fields.
	Please note `childNodes` and `attributes` as we chose to expose them with a different type signiature to make cross platform implementations simpler.
	Also note that `hasAttributes`, `getAttribute`, `setAttribute` and `removeAttribute` are also exposed, even though these belong to Element, not Node.

	On other targets, this wraps `Xml` and provides an interface similar to `js.html.Node`.
	Not every property or method is implemented, but enough are implemented to allow our various Detox methods to function correctly.

	Classes for interacting with DOMNode include:

	- `dtx.single.ElementManipulation`
	- `dtx.single.DOMManipulation`
	- `dtx.single.Traversing`
	- `dtx.single.EventManagement`
	- `dtx.single.Style`
**/
typedef DOMNode = 
#if js
	dtx.js.DOMNode
#else
	dtx.mo.DOMNode
#end;

/**
	A generic DOM Element.

	Similar to `dtx.DOMNode` this changes depending on the platform.
	`DOMElement` is a typedef alias for `js.html.Element` on Javascript, and `DOMNode` on other platforms.

	At some point it may be worth changing this as now that DOMNode is an abstract, this extension is sometimes awkward and leads to unexpected behaviour.
**/
typedef DOMElement = 
#if js 
	js.html.Element 
#else 
	DOMNode 
#end;

/**
	An element that can contain other elements.

	On JS this is a typedef capable of using `querySelector` and `querySelectorAll`, so usually an Element or a Document.
	On other platforms this is simple an alias for `Xml`.
**/
typedef DocumentOrElement = 
#if js
	dtx.js.DocumentOrElement
#else
	dtx.mo.DocumentOrElement
#end;

typedef SingleTraverse = 
#if js
	dtx.js.single.Traversing
#else
	dtx.mo.single.Traversing
#end;

typedef CollectionTraverse = 
#if js
	dtx.js.collection.Traversing
#else
	dtx.mo.collection.Traversing
#end;
