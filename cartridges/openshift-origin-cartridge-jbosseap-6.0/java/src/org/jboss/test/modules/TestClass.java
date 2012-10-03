package org.jboss.test.modules;

/**
 * @author Scott stark (sstark@redhat.com) (C) 2011 Red Hat Inc.
 * @version $Revision:$
 */
public class TestClass {
    public static String validate() {
        StringBuilder tmp = new StringBuilder("TestClass.info\n");
        tmp.append(TestClass.class.getProtectionDomain());
        return tmp.toString();
    }
}
