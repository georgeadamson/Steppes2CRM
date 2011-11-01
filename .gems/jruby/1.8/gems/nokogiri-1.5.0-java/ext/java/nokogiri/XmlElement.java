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

package nokogiri;

import static nokogiri.internals.NokogiriHelpers.rubyStringToString;
import nokogiri.internals.SaveContextVisitor;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Attr;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;

/**
 * Class for Nokogiri::XML::Element
 * 
 * @author sergio
 * @author Yoko Harada <yokolet@gamil.com>
 */
@JRubyClass(name="Nokogiri::XML::Element", parent="Nokogiri::XML::Node")
public class XmlElement extends XmlNode {

    public XmlElement(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }

    public XmlElement(Ruby runtime, RubyClass klazz, Node element) {
        super(runtime, klazz, element);
    }
    
    @Override
    public void setNode(ThreadContext context, Node node) {
        this.node = node;
        if (node != null) {
            resetCache();
            if (node.getNodeType() != Node.DOCUMENT_NODE) {
                doc = document(context);
                setInstanceVariable("@document", doc);
                if (doc != null) {
                    RuntimeHelpers.invoke(context, doc, "decorate", this);
                }
            }
        }
    }

    @Override
    @JRubyMethod(name = {"add_namespace_definition", "add_namespace"})
    public IRubyObject add_namespace_definition(ThreadContext context,
                                                IRubyObject prefix,
                                                IRubyObject href) {
        Element element = (Element) node;

        final String uri = "http://www.w3.org/2000/xmlns/";
        String qName =
            prefix.isNil() ? "xmlns" : "xmlns:" + rubyStringToString(prefix);
        element.setAttributeNS(uri, qName, rubyStringToString(href));

        XmlNamespace ns = (XmlNamespace) super.add_namespace_definition(context, prefix, href);
        updateNodeNamespaceIfNecessary(context, ns);

        return ns;
    }

    @Override
    public boolean isElement() { return true; }

    @Override
    @JRubyMethod(visibility = Visibility.PRIVATE)
    public IRubyObject get(ThreadContext context, IRubyObject rbkey) {
        if (rbkey == null || rbkey.isNil()) context.getRuntime().getNil();
        String key = rubyStringToString(rbkey);
        Element element = (Element) node;
        String value = element.getAttribute(key);
        if(!value.equals("")){
            return context.getRuntime().newString(value);
        }
        return context.getRuntime().getNil();
    }

    @Override
    public IRubyObject key_p(ThreadContext context, IRubyObject rbkey) {
        String key = rubyStringToString(rbkey);
        Element element = (Element) node;
        return context.getRuntime().newBoolean(element.hasAttribute(key));
    }

    @Override
    public IRubyObject op_aset(ThreadContext context,
                               IRubyObject rbkey,
                               IRubyObject rbval) {
        String key = rubyStringToString(rbkey);
        String val = rubyStringToString(rbval);
        Element element = (Element) node;
        element.setAttribute(key, val);
        return this;
    }

    @Override
    public IRubyObject remove_attribute(ThreadContext context, IRubyObject name) {
        String key = name.convertToString().asJavaString();
        Element element = (Element) node;
        element.removeAttribute(key);
        return this;
    }

    @Override
    public void relink_namespace(ThreadContext context) {
        Element e = (Element) node;

        e.getOwnerDocument().renameNode(e, e.lookupNamespaceURI(e.getPrefix()), e.getNodeName());

        if(e.hasAttributes()) {
            NamedNodeMap attrs = e.getAttributes();

            for(int i = 0; i < attrs.getLength(); i++) {
                Attr attr = (Attr) attrs.item(i);
                String nsUri = "";
                String prefix = attr.getPrefix();
                String nodeName = attr.getNodeName();
                if("xml".equals(prefix)) {
                    nsUri = "http://www.w3.org/XML/1998/namespace";
                } else if("xmlns".equals(prefix) || nodeName.equals("xmlns")) {
                    nsUri = "http://www.w3.org/2000/xmlns/";
                } else {
                    nsUri = attr.lookupNamespaceURI(nodeName);
                }

                e.getOwnerDocument().renameNode(attr, nsUri, nodeName);

            }
        }

        if(e.hasChildNodes()) {
            ((XmlNodeSet) children(context)).relink_namespace(context);
        }
    }
    
    @Override
    public void accept(ThreadContext context, SaveContextVisitor visitor) {
        visitor.enter((Element)node);
        XmlNodeSet xmlNodeSet = (XmlNodeSet) children(context);
        if (xmlNodeSet.length() > 0) {
            RubyArray array = (RubyArray) xmlNodeSet.to_a(context);
            for(int i = 0; i < array.getLength(); i++) {
                Object item = array.get(i);
                if (item instanceof XmlNode) {
                  XmlNode cur = (XmlNode) item;
                  cur.accept(context, visitor);
                } else if (item instanceof XmlNamespace) {
                    XmlNamespace cur = (XmlNamespace)item;
                    cur.accept(context, visitor);
                }
            }
        }
        visitor.leave((Element)node);
    }
}
