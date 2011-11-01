/**
 * (The MIT License)
 *
 * Copyright (c) 2008 - 2011:
 *
 * * {Aaron Patterson}[http://tenderlovemaking.com]
 * * {Mike Dalessio}[http://mike.daless.io]
 * * {Charles Nutter}[http://blog.headius.com]
 * * {Sergio Arbeo}[http://www.serabe.com]
 * * {Patrick Mahoney}[http://polycrystal.org]
 * * {Yoko Harada}[http://yokolet.blogspot.com]
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * 'Software'), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

package nokogiri.internals;

import static nokogiri.internals.NokogiriHelpers.encodeJavaString;
import static nokogiri.internals.NokogiriHelpers.isNotXmlEscaped;

import java.util.Stack;

import org.cyberneko.html.HTMLElements;
import org.w3c.dom.Attr;
import org.w3c.dom.CDATASection;
import org.w3c.dom.Comment;
import org.w3c.dom.Document;
import org.w3c.dom.DocumentType;
import org.w3c.dom.Element;
import org.w3c.dom.Entity;
import org.w3c.dom.EntityReference;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.Notation;
import org.w3c.dom.ProcessingInstruction;
import org.w3c.dom.Text;

/**
 * A class for serializing a document.
 * 
 * @author sergio
 * @author Patrick Mahoney <pat@polycrystal.org>
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class SaveContextVisitor {

    private StringBuffer buffer;
    private Stack<String> indentation;
    private String encoding, indentString;
    private boolean format, noDecl, noEmpty, noXhtml, asXhtml, asXml, asHtml, asBuilder, htmlDoc, fragment;

    /*
     * U can't touch this.
     * http://www.youtube.com/watch?v=WJ2ZFVx6A4Q
     *
     * Taken from libxml save options.
     */

    public static final int FORMAT = 1;
    public static final int NO_DECL = 2;
    public static final int NO_EMPTY = 4;
    public static final int NO_XHTML = 8;
    public static final int AS_XHTML = 16;
    public static final int AS_XML = 32;
    public static final int AS_HTML = 64;
    public static final int AS_BUILDER = 128;

    public SaveContextVisitor(int options, String indent, String encoding, boolean htmlDoc, boolean fragment) {
        buffer = new StringBuffer();
        this.encoding = encoding;
        indentation = new Stack<String>(); indentation.push("");
        this.htmlDoc = htmlDoc;
        this.fragment = fragment;
        format = (options & FORMAT) == FORMAT;
        
        noDecl = (options & NO_DECL) == NO_DECL;
        noEmpty = (options & NO_EMPTY) == NO_EMPTY;
        noXhtml = (options & NO_XHTML) == NO_XHTML;
        asXhtml = (options & AS_XHTML) == AS_XHTML;
        asXml = (options & AS_XML) == AS_XML;
        asHtml = (options & AS_HTML) == AS_HTML;
        asBuilder = (options & AS_BUILDER) == AS_BUILDER;
        if ((format && indent == null) || (format && indent.length() == 0)) indent = "  "; // default, two spaces
        if ((!format && indent != null) && indent.length() > 0) format = true;
        if ((asBuilder && indent == null) || (asBuilder && indent.length() == 0)) indent = "  "; // default, two spaces
        indentString = indent;
        if (!asXml && !asHtml && !asXhtml && !asBuilder) asXml = true;
    }
    
    @Override
    public String toString() {
        return (new String(buffer));
    }
    
    public void setHtmlDoc(boolean htmlDoc) {
        this.htmlDoc = htmlDoc;
    }
    
    public void setEncoding(String encoding) {
        this.encoding = encoding;
    }
    
    public boolean enter(Node node) {
        if (node instanceof Document) {
            return enter((Document)node);
        }
        if (node instanceof Element) {
            return enter((Element)node);
        }
        if (node instanceof Attr) {
            return enter((Attr)node);
        }
        if (node instanceof Text) {
            return enter((Text)node);
        }
        if (node instanceof CDATASection) {
            return enter((CDATASection)node);
        }
        if (node instanceof Comment) {
            return enter((Comment)node);
        }
        if (node instanceof DocumentType) {
            return enter((DocumentType)node);
        }
        if (node instanceof Entity) {
            return enter((Entity)node);
        }
        if (node instanceof EntityReference) {
            return enter((EntityReference)node);
        }
        if (node instanceof Notation) {
            return enter((Notation)node);
        }
        if (node instanceof ProcessingInstruction) {
            return enter((ProcessingInstruction)node);
        }
        return false;
    }
    
    public void leave(Node node) {
        if (node instanceof Document) {
            leave((Document)node);
            return;
        }
        if (node instanceof Element) {
            leave((Element)node);
            return;
        }
        if (node instanceof Attr) {
            leave((Attr)node);
            return;
        }
        if (node instanceof Text) {
            leave((Text)node);
            return;
        }
        if (node instanceof CDATASection) {
            leave((CDATASection)node);
            return;
        }
        if (node instanceof Comment) {
            leave((Comment)node);
            return;
        }
        if (node instanceof DocumentType) {
            leave((DocumentType)node);
            return;
        }
        if (node instanceof Entity) {
            leave((Entity)node);
            return;
        }
        if (node instanceof EntityReference) {
            leave((EntityReference)node);
            return;
        }
        if (node instanceof Notation) {
            leave((Notation)node);
            return;
        }
        if (node instanceof ProcessingInstruction) {
            leave((ProcessingInstruction)node);
            return;
        }
    }
    
    public boolean enter(String string) {
        buffer.append(string);
        return true;
    }
    
    public void leave(String string) {
        // no-op
    }
    
    public boolean enter(Attr attr) {
        String name = attr.getName();
        buffer.append(name);
        if (!asHtml || !isHtmlBooleanAttr(name)) {
            buffer.append("=");
            buffer.append("\"");
            buffer.append(serializeAttrTextContent(attr.getValue(), htmlDoc));
            buffer.append("\"");
        }
        return true;
    }
    
    public static final String[] HTML_BOOLEAN_ATTRS = {
        "checked", "compact", "declare", "defer", "disabled", "ismap",
        "multiple", "nohref", "noresize", "noshade", "nowrap", "readonly",
        "selected"
    };
    
    private boolean isHtmlBooleanAttr(String name) {
        for (String s : HTML_BOOLEAN_ATTRS) {
            if (s.equals(name)) return true;
        }
        return false;
    }
    
    private String serializeAttrTextContent(String s, boolean htmlDoc) {
        if (s == null) return "";

        char[] c = s.toCharArray();
        StringBuffer buffer = new StringBuffer(c.length);

        for(int i = 0; i < c.length; i++) {
            switch(c[i]){
            case '\n': buffer.append("&#10;"); break;
            case '\r': buffer.append("&#13;"); break;
            case '\t': buffer.append("&#9;"); break;
            case '"': if (htmlDoc) buffer.append("%22"); 
                else buffer.append("&quot;");
                break;
            case '<': buffer.append("&lt;"); break;
            case '>': buffer.append("&gt;"); break;
            case '&': buffer.append("&amp;"); break;
            default: buffer.append(c[i]);
            }
        }

        return buffer.toString();
    }

    public void leave(Attr attr) {
        // no-op
    }
    
    public boolean enter(CDATASection cdata) {
        buffer.append("<![CDATA[");
        buffer.append(cdata.getData());
        buffer.append("]]>");
        return true;
    }
    
    public void leave(CDATASection cdata) {
        // no-op
    }

    public boolean enter(Comment comment) {
        buffer.append("<!--");
        buffer.append(comment.getData());
        buffer.append("-->");
        return true;
    }
    
    public void leave(Comment comment) {
        // no-op
    }
    
    public boolean enter(Document document) {
        if (!noDecl) {
            buffer.append("<?xml version=\"");
            buffer.append(document.getXmlVersion());
            buffer.append("\"");

            if (encoding != null) {
                buffer.append(" encoding=\"");
                buffer.append(encoding.toUpperCase());
                buffer.append("\"");
            }
            buffer.append("?>\n");
        }
        return true;
    }
    
    public void leave(Document document) {
        // no-op
    }
    
    public boolean enter(DocumentType docType) {
        String name = docType.getName();
        String pubId = docType.getPublicId();
        String sysId = docType.getSystemId();
        String internalSubset = docType.getInternalSubset();
        if (docType.getPreviousSibling() != null) {
            buffer.append("\n");
        }
        buffer.append("<!DOCTYPE " + name + " ");
        if (pubId != null) {
            buffer.append("PUBLIC \"" + pubId + "\"");
            if (sysId != null) buffer.append(" \"" + sysId + "\"");
        } else if (sysId != null) {
            buffer.append("SYSTEM \"" + sysId + "\"");
        }
        if (internalSubset != null) {
            buffer.append(" [");
            buffer.append(internalSubset);
            buffer.append("]");
        }
        buffer.append(">\n");
        return true;
    }
    
    public void leave(DocumentType docType) {
        // no-op
    }

    public boolean enter(Element element) {
        String current = indentation.peek();
        buffer.append(current);
        if (needIndent()) {
            indentation.push(current + indentString);
        }
        String name = element.getTagName();
        buffer.append("<" + name);
        NamedNodeMap attrs = element.getAttributes();
        for (int i=0; i<attrs.getLength(); i++) {
            Attr attr = (Attr) attrs.item(i);
            if (attr.getSpecified()) {
                buffer.append(" ");
                enter(attr);
                leave(attr);
            }
        }
        if (element.hasChildNodes()) {
            buffer.append(">");
            if (needBreakInOpening(element)) buffer.append("\n");
            return true;
        }
        // no child
        if (asHtml) {
            buffer.append(">");   
        } else if (asXhtml) {
            buffer.append(" />");
        } else if (asXml && noEmpty) {
            buffer.append(">");
        } else {
            buffer.append("/>");
        }
        if (needBreakInOpening(element)) {
            buffer.append("\n");
        }
        return true;
    }
    
    private boolean needIndent() {
        if (fragment) return false;  // a given option might be fragment and format. fragment matters
        if (format || asBuilder) return true;
        return false;
    }
    
    private boolean needBreakInOpening(Element element) {
        if (fragment) return false;
        if (format) return true;
        if (asBuilder && element.getFirstChild() != null && element.getFirstChild().getNodeType() == Node.ELEMENT_NODE) return true;
        if (format && element.getNextSibling() == null && element.hasChildNodes()) return true;
        return false;
    }
    
    private boolean isEmpty(String name) {
        HTMLElements.Element element = HTMLElements.getElement(name);
        return element.isEmpty();
    }
    
    public void leave(Element element) {
        String name = element.getTagName();
        if (element.hasChildNodes()) {
            if (needIndentInClosing(element)) {
                indentation.pop();
                buffer.append(indentation.peek());
            } else if (asBuilder) {
                indentation.pop();
            }
            buffer.append("</" + name + ">");
            if (needBreakInClosing()) {
                buffer.append("\n");
            }
            return;
        }
        // no child, but HTML might need a closing tag.
        if (asHtml || noEmpty) {
            if (!isEmpty(name) && noEmpty) {
                buffer.append("</" + name + ">");
            }
        }
        if (needBreakInClosing()) {
            indentation.pop();
            buffer.append("\n");
        }
    }
    
    private boolean needIndentInClosing(Element element) {
        if (fragment) return false;  // a given option might be fragment and format. fragment matters
        if (format) return true;
        if (asBuilder && element.getFirstChild() != null && element.getFirstChild().getNodeType() == Node.ELEMENT_NODE) return true;
        return false;
    }
    
    private boolean needBreakInClosing() {
        if (fragment) return false;
        if (format || asBuilder) return true;
        return false;
    }

    public boolean enter(Entity entity) {
        String name = entity.getNodeName();
        String pubId = entity.getPublicId();
        String sysId = entity.getSystemId();
        String notation = entity.getNotationName();
        buffer.append("<!ENTITY ");
        buffer.append(name);
        if (pubId != null) {
            buffer.append(" PUBLIC \"");
            buffer.append(pubId);
            buffer.append("\"");
        }
        if (sysId != null) {
            buffer.append(" SYSTEM \"");
            buffer.append(sysId);
            buffer.append("\"");
        }
        if (notation != null) {
            buffer.append(" NDATA ");
            buffer.append(notation);
        }
        buffer.append(">");
        return true;
    }
    
    public void leave(Entity entity) {
        // no-op
    }

    public boolean enter(EntityReference entityRef) {
        // no-op?
        return true;
    }
    
    public void leave(EntityReference entityRef) {
        // no-op
    }
    
    public boolean enter(Notation notation) {
        String name = notation.getNodeName();
        String pubId = notation.getPublicId();
        String sysId = notation.getSystemId();
        buffer.append("<!NOTATION ");
        buffer.append(name);
        if (pubId != null) {
            buffer.append(" PUBLIC \"");
            buffer.append(pubId);
            buffer.append("\"");
            if (sysId != null) {
                buffer.append(" \"");
                buffer.append(sysId);
                buffer.append("\"");
            }
        } else if (sysId != null) {
            buffer.append(" SYSTEM \"");
            buffer.append(sysId);
            buffer.append("\"");
        }
        buffer.append(">");
        return true;
    }
    
    public void leave(Notation notation) {
        // no-op
    }

    public boolean enter(ProcessingInstruction pi) {
        buffer.append("<?");
        buffer.append(pi.getTarget());
        buffer.append(" ");
        buffer.append(pi.getData());
        if (asHtml) buffer.append(">");
        else buffer.append("?>");
        buffer.append("\n");
        return true;
    }
    
    public void leave(ProcessingInstruction pi) {
        // no-op
    }

    private static char lineSeparator = '\n'; // System.getProperty("line.separator"); ?
    public boolean enter(Text text) {
        String textContent = text.getNodeValue();
        if (needIndentText() && "".equals(textContent.trim())) return true;
        if (needIndentText()) {
            String current = indentation.peek();
            buffer.append(current);
            indentation.push(current + indentString);
            if (textContent.charAt(0) == lineSeparator) textContent = textContent.substring(1);    
        }
        if (isNotXmlEscaped(textContent)) {
            textContent = encodeJavaString(textContent);
        }
        if (getEncoding(text) == null) {
            textContent = encodeStringToHtmlEntity(textContent);
        }
        buffer.append(textContent);
        return true;
    }
    
    private boolean needIndentText() {
        if (fragment) return false;
        if (format) return true;
        return false;
    }
    
    public void leave(Text text) {
        String textContent = text.getNodeValue();
        if (needIndentText() && !"".equals(textContent.trim())) {
            indentation.pop();
            if (textContent.charAt(textContent.length()-1) != lineSeparator) {
                buffer.append("\n");
            }
        }
    }
    
    private String getEncoding(Text text) {
        if (encoding != null) return encoding;
        encoding = text.getOwnerDocument().getInputEncoding();
        return encoding;
    }
    
    private String encodeStringToHtmlEntity(String text) {
        int last = 126; // = U+007E. No need to encode under U+007E.
        StringBuffer sb = new StringBuffer();
        for (int i=0; i<text.length(); i++) {
            int codePoint = text.codePointAt(i);
            if (codePoint > last) sb.append("&#x" + Integer.toHexString(codePoint) + ";");
            else sb.append(text.charAt(i));
        }
        return new String(sb);
    }

}
